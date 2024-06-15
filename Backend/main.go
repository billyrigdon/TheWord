package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"strconv"
	"time"

	"github.com/dgrijalva/jwt-go"
	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

var db *gorm.DB

type User struct {
	UserID          uint   `gorm:"primaryKey"`
	Email           string `gorm:"unique"`
	Username        string
	PasswordHash    string
	PublicProfile   bool
	PrimaryColor    int
	HighlightColor  int
	DarkMode        bool
	TranslationId   string
	TranslationName string
}

type FriendRequestResponse struct {
	UserID   uint   `json:"user_id"`
	Username string `json:"username"`
}

type UserVerse struct {
	UserVerseID uint `gorm:"primaryKey"`
	VerseID     string
	Content     string
	Verse       string
	UserID      uint
	Note        string
}

type UserResponse struct {
	UserID          uint   `json:"user_id"`
	Username        string `json:"username"`
	PublicProfile   bool   `json:"public_profile"`
	PrimaryColor    int    `json:"primary_color"`
	HighlightColor  int    `json:"highlight_color"`
	DarkMode        bool   `json:"dark_mode"`
	TranslationId   string `json:"translation_id"`
	TranslationName string `json:"translation_name"`
}

type Like struct {
	LikeID      uint `gorm:"primaryKey"`
	UserID      uint
	UserVerseID int
}

type Comment struct {
	CommentID       uint `gorm:"primaryKey"`
	Content         string
	UserID          uint
	Username        string
	UserVerseID     int
	ParentCommentID *uint
}

type Friend struct {
	ID        uint   `gorm:"primaryKey"` // Primary key for the record
	UserID    uint   `gorm:"index"`      // ID of the user who initiated the friend request
	FriendID  uint   `gorm:"index"`      // ID of the friend
	Status    string // e.g., "requested", "accepted", "rejected", ""
	CreatedAt time.Time
	UpdatedAt time.Time
}

type LoginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

type RegistrationRequest struct {
	Email    string `json:"email"`
	Username string `json:"username"`
	Password string `json:"password"`
}

type Claims struct {
	UserID uint `json:"user_id"`
	jwt.StandardClaims
}

var jwtKey = []byte("secret_key")

func main() {
	dbUser := os.Getenv("DB_USER")
	dbPassword := os.Getenv("DB_PASSWORD")
	dbName := os.Getenv("DB_NAME")
	dbHost := os.Getenv("DB_HOST")

	dsn := fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=5432 sslmode=disable",
		dbHost, dbUser, dbPassword, dbName)

	var err error
	db, err = gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatalf("failed to connect to database: %v", err)
	}

	db.AutoMigrate(&User{}, &UserVerse{}, &Like{}, &Comment{}, &Friend{})
	log.Println("Database tables created or already exist.")

	createAdminUser()

	r := gin.Default()

	r.POST("/register", registerUser)
	r.POST("/login", loginUser)
	r.GET("/user/:id", authMiddleware, getUser)
	r.POST("/verse", authMiddleware, createVerse)
	r.GET("/verse/:id", authMiddleware, getVerse)
	r.DELETE("/verses/:id", authMiddleware, deleteVerse)
	r.POST("/verse/:id/toggle-like", authMiddleware, toggleLike)
	r.POST("/verse/:id/comment", authMiddleware, addComment)
	r.GET("/user/settings", authMiddleware, getUserSettings)
	r.POST("/user/settings", authMiddleware, updateUserSettings)
	r.GET("/verses/public", authMiddleware, getPublicVerses)
	r.POST("/verses/save", authMiddleware, saveVerse)
	r.GET("/verses/saved", authMiddleware, getSavedVerses)
	r.PUT("/verses/:id", authMiddleware, updateVerse)
	r.GET("/verse/:id/comments", authMiddleware, getComments)
	r.GET("/verse/:id/likes", authMiddleware, getLikesCount)
	r.GET("/verse/:id/comments/count", authMiddleware, getCommentCount)
	r.GET("/friends/suggested", authMiddleware, listSuggestedFriends)
	r.POST("/friends/:id", authMiddleware, addFriend)
	r.DELETE("/friends/:id", authMiddleware, removeFriend)
	r.GET("/friends", authMiddleware, listFriends)
	r.GET("/friends/requests", authMiddleware, listFriendRequests)
	r.POST("/friends/requests/:id/respond", authMiddleware, respondFriendRequest)

	r.Run()
}

func getUserSettings(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	var user User
	if err := db.First(&user, "user_id = ?", userID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"primary_color":    user.PrimaryColor,
		"highlight_color":  user.HighlightColor,
		"dark_mode":        user.DarkMode,
		"public_profile":   user.PublicProfile,
		"translation_id":   user.TranslationId,
		"translation_name": user.TranslationName,
	})
}

func updateUserSettings(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	var req struct {
		PrimaryColor    int    `json:"primary_color"`
		HighlightColor  int    `json:"highlight_color"`
		DarkMode        bool   `json:"dark_mode"`
		PublicProfile   bool   `json:"public_profile"`
		TranslationId   string `json:"translation_id"`
		TranslationName string `json:"translation_name"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	log.Printf("Received settings update: %+v", req) // Log the incoming request

	updates := map[string]interface{}{
		"primary_color":    req.PrimaryColor,
		"highlight_color":  req.HighlightColor,
		"dark_mode":        req.DarkMode,
		"public_profile":   req.PublicProfile,
		"translation_id":   req.TranslationId,
		"translation_name": req.TranslationName,
	}

	if err := db.Model(&User{}).Where("user_id = ?", userID).Updates(updates).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Settings updated successfully"})
}

func getCommentCount(c *gin.Context) {
	userVerseIDStr := c.Param("id")
	userVerseID, err := strconv.Atoi(userVerseIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid UserVerseID"})
		return
	}

	var commentCount int64
	if err := db.Model(&Comment{}).Where("user_verse_id = ?", userVerseID).Count(&commentCount).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to retrieve comment count"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"comment_count": commentCount})
}

func createAdminUser() {
	var user User
	if err := db.First(&user, "email = ?", "admin@example.com").Error; err == nil {
		return
	}

	passwordHash, _ := bcrypt.GenerateFromPassword([]byte("adminpassword"), bcrypt.DefaultCost)
	admin := User{
		Email:           "admin@example.com",
		Username:        "AdminUser",
		PasswordHash:    string(passwordHash),
		PublicProfile:   true,
		PrimaryColor:    0xFF000000, // ARGB for black
		HighlightColor:  0xFFFF0000, // ARGB for red
		DarkMode:        true,
		TranslationId:   "bba9f40183526463-01",
		TranslationName: "Berean Standard Bible",
	}
	db.Create(&admin)
	log.Println("Admin user created or already exists.")
}

func addFriend(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	friendIDStr := c.Param("id")
	friendID, err := strconv.Atoi(friendIDStr)
	if err != nil || userID == uint(friendID) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid friend ID"})
		return
	}

	var existingFriend Friend
	// Check if any friend relationship or request already exists
	if err := db.Where("(user_id = ? AND friend_id = ?) OR (user_id = ? AND friend_id = ?)", userID, friendID, friendID, userID).
		First(&existingFriend).Error; err == nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Friend request or relationship already exists"})
		return
	}

	// Create a new friend request
	newFriendRequest := Friend{
		UserID:    userID,
		FriendID:  uint(friendID),
		Status:    "requested",
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}
	if err := db.Create(&newFriendRequest).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to send friend request"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Friend request sent"})
}

func removeFriend(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	friendIDStr := c.Param("id")
	friendID, err := strconv.Atoi(friendIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid friend ID"})
		return
	}

	var friend Friend
	// Check for any existing friendship or friend request in both directions
	if err := db.Where("(user_id = ? AND friend_id = ?) OR (user_id = ? AND friend_id = ?)", userID, friendID, friendID, userID).
		First(&friend).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Friendship not found"})
		return
	}

	// Remove the friendship or friend request
	if err := db.Delete(&friend).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to remove friend"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Friend removed successfully"})
}

func listFriends(c *gin.Context) {
	userID := c.MustGet("userID").(uint)

	var friends []User
	db.Table("users").
		Select("DISTINCT users.user_id, users.username, users.public_profile, users.primary_color, users.highlight_color, users.dark_mode, users.translation_id, users.translation_name").
		Joins("JOIN friends ON (friends.friend_id = users.user_id AND friends.user_id = ?) OR (friends.user_id = users.user_id AND friends.friend_id = ?)", userID, userID).
		Where("friends.status = 'accepted'").
		Find(&friends)

	var friendResponses []UserResponse
	for _, friend := range friends {
		friendResponses = append(friendResponses, UserResponse{
			UserID:          friend.UserID,
			Username:        friend.Username,
			PublicProfile:   friend.PublicProfile,
			PrimaryColor:    friend.PrimaryColor,
			HighlightColor:  friend.HighlightColor,
			DarkMode:        friend.DarkMode,
			TranslationId:   friend.TranslationId,
			TranslationName: friend.TranslationName,
		})
	}

	c.JSON(http.StatusOK, friendResponses)
}

func listSuggestedFriends(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User ID not found"})
		return
	}
	userIDUint := userID.(uint)

	var excludedUserIDs []uint

	// Retrieve all related user IDs to exclude
	db.Table("friends").
		Select("friend_id").
		Where("user_id = ? AND status IN ('accepted', 'requested', 'rejected')", userIDUint).
		Scan(&excludedUserIDs)
	db.Table("friends").
		Select("user_id").
		Where("friend_id = ? AND status IN ('accepted', 'requested', 'rejected')", userIDUint).
		Scan(&excludedUserIDs)

	excludedUserIDs = append(excludedUserIDs, userIDUint)

	// Use a map to ensure unique IDs
	excludedUserMap := make(map[uint]struct{})
	for _, id := range excludedUserIDs {
		excludedUserMap[id] = struct{}{}
	}

	uniqueExcludedUserIDs := make([]uint, 0, len(excludedUserMap))
	for id := range excludedUserMap {
		uniqueExcludedUserIDs = append(uniqueExcludedUserIDs, id)
	}

	// Retrieve users not in the exclusion list and with public profile
	var suggestedFriends []User
	if err := db.Table("users").
		Select("user_id, username, public_profile, primary_color, highlight_color, dark_mode, translation_id, translation_name").
		Where("public_profile = true AND user_id NOT IN (?)", uniqueExcludedUserIDs).
		Find(&suggestedFriends).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to retrieve suggested friends"})
		return
	}

	var suggestedFriendResponses []UserResponse
	for _, suggestedFriend := range suggestedFriends {
		suggestedFriendResponses = append(suggestedFriendResponses, UserResponse{
			UserID:          suggestedFriend.UserID,
			Username:        suggestedFriend.Username,
			PublicProfile:   suggestedFriend.PublicProfile,
			PrimaryColor:    suggestedFriend.PrimaryColor,
			HighlightColor:  suggestedFriend.HighlightColor,
			DarkMode:        suggestedFriend.DarkMode,
			TranslationId:   suggestedFriend.TranslationId,
			TranslationName: suggestedFriend.TranslationName,
		})
	}

	c.JSON(http.StatusOK, suggestedFriendResponses)
}

// func addFriend(c *gin.Context) {
// 	userID := c.MustGet("userID").(uint)
// 	friendIDStr := c.Param("id")
// 	friendID, err := strconv.Atoi(friendIDStr)
// 	if err != nil || userID == uint(friendID) {
// 		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid friend ID"})
// 		return
// 	}

// 	var friendRequest Friend
// 	// Check if a friend request already exists with any status
// 	if err := db.Where("(user_id = ? AND friend_id = ?) OR (user_id = ? AND friend_id = ?)", userID, friendID, friendID, userID).
// 		First(&friendRequest).Error; err == nil {
// 		c.JSON(http.StatusBadRequest, gin.H{"error": "Friend request already exists"})
// 		return
// 	}

// 	// Create a new friend request
// 	friendRequest = Friend{
// 		UserID:    userID,
// 		FriendID:  uint(friendID),
// 		Status:    "requested",
// 		CreatedAt: time.Now(),
// 		UpdatedAt: time.Now(),
// 	}
// 	if err := db.Create(&friendRequest).Error; err != nil {
// 		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to send friend request"})
// 		return
// 	}

// 	c.JSON(http.StatusOK, gin.H{"message": "Friend request sent"})
// }

// func removeFriend(c *gin.Context) {
// 	userID := c.MustGet("userID").(uint)
// 	friendIDStr := c.Param("id")
// 	friendID, err := strconv.Atoi(friendIDStr)
// 	if err != nil {
// 		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid friend ID"})
// 		return
// 	}

// 	var friend Friend
// 	// Check for an existing friendship or friend request in both directions
// 	if err := db.Where("(user_id = ? AND friend_id = ?) OR (user_id = ? AND friend_id = ?)", userID, friendID, friendID, userID).
// 		First(&friend).Error; err != nil {
// 		c.JSON(http.StatusNotFound, gin.H{"error": "Friendship not found"})
// 		return
// 	}

// 	// Remove the friendship
// 	if err := db.Delete(&friend).Error; err != nil {
// 		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to remove friend"})
// 		return
// 	}

// 	c.JSON(http.StatusOK, gin.H{"message": "Friend removed successfully"})
// }

// func listFriends(c *gin.Context) {
// 	userID := c.MustGet("userID").(uint)

// 	var friends []User
// 	db.Table("users").
// 		Select("DISTINCT users.user_id, users.username, users.public_profile, users.primary_color, users.highlight_color, users.dark_mode, users.translation_id, users.translation_name").
// 		Joins("JOIN friends ON (friends.friend_id = users.user_id AND friends.user_id = ?) OR (friends.user_id = users.user_id AND friends.friend_id = ?)", userID, userID).
// 		Where("users.user_id != ?", userID).
// 		Where("friends.status = 'accepted'").
// 		Find(&friends)

// 	var friendResponses []UserResponse
// 	for _, friend := range friends {
// 		friendResponses = append(friendResponses, UserResponse{
// 			UserID:          friend.UserID,
// 			Username:        friend.Username,
// 			PublicProfile:   friend.PublicProfile,
// 			PrimaryColor:    friend.PrimaryColor,
// 			HighlightColor:  friend.HighlightColor,
// 			DarkMode:        friend.DarkMode,
// 			TranslationId:   friend.TranslationId,
// 			TranslationName: friend.TranslationName,
// 		})
// 	}

// 	c.JSON(http.StatusOK, friendResponses)
// }

// func listSuggestedFriends(c *gin.Context) {
// 	userID, exists := c.Get("userID")
// 	if !exists {
// 		c.JSON(http.StatusUnauthorized, gin.H{"error": "User ID not found"})
// 		return
// 	}
// 	userIDUint := userID.(uint)

// 	// List to store the IDs of users to be excluded
// 	var excludedUserIDs []uint

// 	// Retrieve all related user IDs (both sides of the relationship)
// 	db.Table("friends").
// 		Select("friend_id").
// 		Where("user_id = ? OR friend_id = ?", userIDUint, userIDUint).
// 		Scan(&excludedUserIDs)

// 	// Add the current user's own ID to the exclusion list
// 	excludedUserIDs = append(excludedUserIDs, userIDUint)

// 	// Ensure unique user IDs to be excluded
// 	uniqueUserIDs := make(map[uint]struct{})
// 	for _, id := range excludedUserIDs {
// 		uniqueUserIDs[id] = struct{}{}
// 	}

// 	for id := range uniqueUserIDs {
// 		excludedUserIDs = append(excludedUserIDs, id)
// 	}

// 	// Retrieve users who are not in the exclusion list and have a public profile
// 	var suggestedFriends []User
// 	if err := db.Table("users").
// 		Select("user_id, username, public_profile, primary_color, highlight_color, dark_mode, translation_id, translation_name").
// 		Where("public_profile = true AND user_id NOT IN (?)", excludedUserIDs).
// 		Find(&suggestedFriends).Error; err != nil {
// 		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to retrieve suggested friends"})
// 		return
// 	}

// 	// Convert to a user response struct
// 	var suggestedFriendResponses []UserResponse
// 	for _, suggestedFriend := range suggestedFriends {
// 		suggestedFriendResponses = append(suggestedFriendResponses, UserResponse{
// 			UserID:          suggestedFriend.UserID,
// 			Username:        suggestedFriend.Username,
// 			PublicProfile:   suggestedFriend.PublicProfile,
// 			PrimaryColor:    suggestedFriend.PrimaryColor,
// 			HighlightColor:  suggestedFriend.HighlightColor,
// 			DarkMode:        suggestedFriend.DarkMode,
// 			TranslationId:   suggestedFriend.TranslationId,
// 			TranslationName: suggestedFriend.TranslationName,
// 		})
// 	}

// 	// Return the suggested friends as a JSON response
// 	c.JSON(http.StatusOK, suggestedFriendResponses)
// }

func listFriendRequests(c *gin.Context) {
	userID := c.MustGet("userID").(uint)

	var friendRequests []FriendRequestResponse
	err := db.Table("users").
		Select("users.user_id, users.username").
		Joins("JOIN friends ON friends.user_id = users.user_id").
		Where("friends.friend_id = ? AND friends.status = ?", userID, "requested").
		Scan(&friendRequests).Error

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to retrieve friend requests"})
		return
	}

	c.JSON(http.StatusOK, friendRequests)
}

func respondFriendRequest(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	friendIDStr := c.Param("id")
	friendID, err := strconv.Atoi(friendIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid friend ID"})
		return
	}

	var req struct {
		Accept bool `json:"accept"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var friend Friend
	if err := db.Where("user_id = ? AND friend_id = ? AND status = ?", friendID, userID, "requested").First(&friend).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Friend request not found"})
		return
	}

	if req.Accept {
		friend.Status = "accepted"
		db.Save(&friend)
		c.JSON(http.StatusOK, gin.H{"message": "Friend request accepted"})
	} else {
		friend.Status = "rejected"
		db.Save(&friend)
		c.JSON(http.StatusOK, gin.H{"message": "Friend request declined"})
	}
}

func getLikesCount(c *gin.Context) {
	userVerseIDStr := c.Param("id")
	userVerseID, err := strconv.Atoi(userVerseIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid UserVerseID"})
		return
	}

	var likesCount int64
	if err := db.Model(&Like{}).Where("user_verse_id = ?", userVerseID).Count(&likesCount).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to retrieve likes count"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"likes_count": likesCount})
}

func registerUser(c *gin.Context) {
	var req RegistrationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	passwordHash, _ := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	user := User{
		Email:           req.Email,
		Username:        req.Username,
		PasswordHash:    string(passwordHash),
		PublicProfile:   false,
		PrimaryColor:    4284955319, // ARGB for white
		HighlightColor:  4294961979,
		DarkMode:        true,
		TranslationId:   "bba9f40183526463-01",
		TranslationName: "Berean Standard Bible",
	}

	if err := db.Create(&user).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "User registered successfully"})
}

func loginUser(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var user User
	if err := db.First(&user, "email = ?", req.Email).Error; err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid email or password"})
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid email or password"})
		return
	}

	expirationTime := time.Now().Add(24 * time.Hour)
	claims := &Claims{
		UserID: user.UserID,
		StandardClaims: jwt.StandardClaims{
			ExpiresAt: expirationTime.Unix(),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, err := token.SignedString(jwtKey)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Could not generate token"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"token": tokenString})
}

func getPublicVerses(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	page := c.DefaultQuery("page", "1")
	pageSize := c.DefaultQuery("pageSize", "10")
	pageInt, err := strconv.Atoi(page)
	if err != nil {
		pageInt = 1
	}
	pageSizeInt, err := strconv.Atoi(pageSize)
	if err != nil {
		pageSizeInt = 10
	}

	var friends []uint

	// Retrieve friends who have accepted the user's friend request
	db.Table("friends").
		Where("user_id = ? AND status = 'accepted'", userID).
		Pluck("friend_id", &friends)

	// Retrieve friends who have accepted the user's friend request or the user has accepted
	db.Table("friends").
		Where("friend_id = ? AND status = 'accepted'", userID).
		Pluck("user_id", &friends)

	// Append the user's own ID to include their verses
	friends = append(friends, userID)

	// Remove duplicate IDs
	friends = unique(friends)

	var verses []UserVerse
	offset := (pageInt - 1) * pageSizeInt

	// Fetch verses from the user and friends
	err = db.Joins("JOIN users ON users.user_id = user_verses.user_id").
		Where("user_verses.note != '' AND user_verses.user_id IN (?)", friends).
		Offset(offset).
		Limit(pageSizeInt).
		Find(&verses).Error

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("Failed to retrieve verses: %v", err)})
		return
	}

	c.JSON(http.StatusOK, verses)
}

// Helper function to remove duplicate IDs
func unique(slice []uint) []uint {
	keys := make(map[uint]bool)
	list := []uint{}

	for _, entry := range slice {
		if _, value := keys[entry]; !value {
			keys[entry] = true
			list = append(list, entry)
		}
	}
	return list
}

func saveVerse(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	var verse UserVerse
	if err := c.ShouldBindJSON(&verse); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	verse.UserID = userID

	if err := db.Save(&verse).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message":     "Verse saved successfully",
		"userVerseID": verse.UserVerseID,
	})
}

func updateVerse(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	userVerseID := c.Param("id")

	var req struct {
		Note string `json:"note"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	var verse UserVerse
	if err := db.First(&verse, "user_verse_id = ? AND user_id = ?", userVerseID, userID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Verse not found or you don't have permission to update this verse"})
		return
	}

	verse.Note = req.Note
	if err := db.Save(&verse).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update verse"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Verse updated successfully", "verse": verse})
}

func getSavedVerses(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	page := c.DefaultQuery("page", "1")
	pageSize := c.DefaultQuery("pageSize", "10")
	pageInt, err := strconv.Atoi(page)
	if err != nil {
		pageInt = 1
	}
	pageSizeInt, err := strconv.Atoi(pageSize)
	if err != nil {
		pageSizeInt = 10
	}

	var verses []UserVerse
	offset := (pageInt - 1) * pageSizeInt
	if err := db.Where("user_id = ?", userID).Offset(offset).Limit(pageSizeInt).Find(&verses).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, verses)
}

func getUser(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	var user User
	if err := db.First(&user, "user_id = ?", userID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}
	c.JSON(http.StatusOK, user)
}

func createVerse(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	var verse UserVerse
	if err := c.ShouldBindJSON(&verse); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	verse.UserID = userID
	db.Create(&verse)
	c.JSON(http.StatusOK, verse)
}

func getVerse(c *gin.Context) {
	var verse UserVerse
	if err := db.First(&verse, "user_verse_id = ?", c.Param("id")).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Verse not found"})
		return
	}
	c.JSON(http.StatusOK, verse)
}

func deleteVerse(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	verseID := c.Param("id")

	var verse UserVerse
	// Check if the verse exists and belongs to the current user
	if err := db.First(&verse, "user_verse_id = ? AND user_id = ?", verseID, userID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Verse not found or you don't have permission to delete this verse"})
		return
	}

	// Delete the verse
	if err := db.Delete(&verse).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Verse deleted successfully"})
}

func toggleLike(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	userVerseIDStr := c.Param("id")
	userVerseID, _ := strconv.Atoi(userVerseIDStr)

	var like Like
	if err := db.Where("user_id = ? AND user_verse_id = ?", userID, userVerseID).First(&like).Error; err == nil {
		db.Delete(&like)
		c.JSON(http.StatusOK, gin.H{"message": "Like removed"})
	} else {
		like.UserID = userID
		like.UserVerseID = userVerseID
		db.Create(&like)
		c.JSON(http.StatusOK, gin.H{"message": "Verse liked"})
	}
}

func addComment(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	userVerseID := c.Param("id")

	var comment Comment
	if err := c.ShouldBindJSON(&comment); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	comment.UserID = userID
	comment.UserVerseID, _ = strconv.Atoi(userVerseID)

	parentCommentIDStr := c.Query("parentCommentID")
	if parentCommentIDStr != "" {
		parentCommentID, err := strconv.Atoi(parentCommentIDStr)
		if err == nil {
			parentCommentIDUint := uint(parentCommentID)
			comment.ParentCommentID = &parentCommentIDUint
		}
	}

	// Fetch username of the commenter
	var user User
	if err := db.First(&user, "user_id = ?", userID).Error; err == nil {
		comment.Username = user.Username
	}

	db.Create(&comment)
	c.JSON(http.StatusOK, comment)
}

func getComments(c *gin.Context) {
	userVerseID := c.Param("id")

	var comments []Comment
	err := db.Joins("JOIN users ON users.user_id = comments.user_id").
		Where("comments.user_verse_id = ?", userVerseID).
		Select("comments.*, users.username AS username").
		Find(&comments).Error
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, comments)
}

func authMiddleware(c *gin.Context) {
	tokenString := c.GetHeader("Authorization")
	if tokenString == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Token required"})
		c.Abort()
		return
	}

	if len(tokenString) > 7 && tokenString[:7] == "Bearer " {
		tokenString = tokenString[7:]
	}

	claims := &Claims{}
	token, err := jwt.ParseWithClaims(tokenString, claims, func(token *jwt.Token) (interface{}, error) {
		return jwtKey, nil
	})
	if err != nil || !token.Valid {
		log.Printf("Token error: %v, Valid: %v", err, token.Valid)
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid token"})
		c.Abort()
		return
	}

	c.Set("userID", claims.UserID)
	c.Next()
}
