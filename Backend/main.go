package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt"
	"github.com/lib/pq"
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
	IsPublished bool `json:"is_published"` // New field added
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

type Notification struct {
	NotificationID uint      `gorm:"primaryKey"`
	UserID         uint      `gorm:"not null"`
	Content        string    `gorm:"not null"`
	UserVerseID    int       `gorm:"index"`
	CommentID      *uint     `gorm:"index"`
	CreatedAt      time.Time `gorm:"autoCreateTime"`
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

	db.AutoMigrate(&User{}, &UserVerse{}, &Like{}, &Comment{}, &Friend{}, &Notification{})
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
	r.PUT("/verse/:id/comment/:commentID", authMiddleware, updateComment)
	r.DELETE("/verse/:id/comment/:commentID", authMiddleware, deleteComment)
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
	r.POST("/verse/:id/publish", authMiddleware, publishVerse)
	r.POST("/verse/:id/unpublish", authMiddleware, unpublishVerse)
	r.GET("/commentRequests", authMiddleware, getCommentRequests)
	r.DELETE("/notifications/comments/:id", authMiddleware, deleteCommentNotification)
	r.Run()
}

func deleteCommentNotification(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	notificationID := c.Param("id")

	if err := db.Where("user_id = ? AND notification_id = ?", userID, notificationID).Delete(&Notification{}).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete comment notification"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Notification deleted successfully"})
}

func getUserSettings(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	var user User
	if err := db.First(&user, "user_id = ?", userID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"user_id":          user.UserID,
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

	passwordHash, _ := bcrypt.GenerateFromPassword([]byte("hackerman"), bcrypt.DefaultCost)
	admin := User{
		Email:           "admin@example.com",
		Username:        "Tom",
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

	var friends []struct {
		UserID          uint   `json:"user_id"`
		Username        string `json:"username"`
		PublicProfile   bool   `json:"public_profile"`
		PrimaryColor    int    `json:"primary_color"`
		HighlightColor  int    `json:"highlight_color"`
		DarkMode        bool   `json:"dark_mode"`
		TranslationId   string `json:"translation_id"`
		TranslationName string `json:"translation_name"`
		MutualFriends   int    `json:"mutual_friends"`
		TotalLikeCount  int    `json:"total_like_count"`
	}

	db.Raw(`
        SELECT 
            u.user_id, 
            u.username, 
            u.public_profile, 
            u.primary_color, 
            u.highlight_color, 
            u.dark_mode, 
            u.translation_id, 
            u.translation_name,
            (
                SELECT COUNT(DISTINCT mutual_friend_id)
                FROM (
                    SELECT f1.friend_id AS mutual_friend_id
                    FROM friends f1
                    WHERE f1.status = 'accepted' 
                    AND f1.user_id = u.user_id 
                    AND f1.friend_id IN (
                        SELECT f2.friend_id 
                        FROM friends f2
                        WHERE f2.status = 'accepted'
                        AND f2.user_id = ?
                    )
                    
                    UNION
                    
                    SELECT f1.user_id AS mutual_friend_id
                    FROM friends f1
                    WHERE f1.status = 'accepted' 
                    AND f1.friend_id = u.user_id 
                    AND f1.user_id IN (
                        SELECT f2.friend_id 
                        FROM friends f2
                        WHERE f2.status = 'accepted'
                        AND f2.user_id = ?
                    )
                    
                    UNION
                    
                    SELECT f1.friend_id AS mutual_friend_id
                    FROM friends f1
                    WHERE f1.status = 'accepted'
                    AND f1.user_id = u.user_id 
                    AND f1.friend_id IN (
                        SELECT f2.user_id 
                        FROM friends f2
                        WHERE f2.status = 'accepted'
                        AND f2.friend_id = ?
                    )
                    
                    UNION
                    
                    SELECT f1.user_id AS mutual_friend_id
                    FROM friends f1
                    WHERE f1.status = 'accepted'
                    AND f1.friend_id = u.user_id 
                    AND f1.user_id IN (
                        SELECT f2.user_id 
                        FROM friends f2
                        WHERE f2.status = 'accepted'
                        AND f2.friend_id = ?
                    )
                ) AS mutual_friends
            ) AS mutual_friends,
            (
                SELECT COUNT(*)
                FROM likes
                WHERE likes.user_id = u.user_id
            ) AS total_like_count
        FROM users u
        INNER JOIN friends f ON (
            (f.friend_id = u.user_id AND f.user_id = ? AND f.status = 'accepted')
            OR
            (f.user_id = u.user_id AND f.friend_id = ? AND f.status = 'accepted')
        )
    `, userID, userID, userID, userID, userID, userID).Scan(&friends)

	c.JSON(http.StatusOK, friends)
}

func listSuggestedFriends(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User ID not found"})
		return
	}
	userIDUint := userID.(uint)

	var excludedUserIDs []uint

	// Retrieve all related user IDs to exclude (accepted, requested, or rejected)
	db.Raw(`
        SELECT DISTINCT user_id 
        FROM (
            SELECT friend_id AS user_id 
            FROM friends 
            WHERE user_id = $1 AND status IN ('accepted', 'requested', 'rejected')
            UNION
            SELECT user_id 
            FROM friends 
            WHERE friend_id = $1 AND status IN ('accepted', 'requested', 'rejected')
        ) AS related_users
    `, userIDUint).Scan(&excludedUserIDs)

	// Add the current user ID to the exclusion list
	excludedUserIDs = append(excludedUserIDs, userIDUint)

	var suggestedFriends []struct {
		UserID          uint   `json:"user_id"`
		Username        string `json:"username"`
		MutualFriends   int    `json:"mutual_friends"`
		TotalLikeCount  int    `json:"total_like_count"`
		PublicProfile   bool   `json:"public_profile"`
		PrimaryColor    int    `json:"primary_color"`
		HighlightColor  int    `json:"highlight_color"`
		DarkMode        bool   `json:"dark_mode"`
		TranslationId   string `json:"translation_id"`
		TranslationName string `json:"translation_name"`
	}

	db.Raw(`
        SELECT 
            u.user_id, 
            u.username, 
            u.public_profile, 
            u.primary_color, 
            u.highlight_color, 
            u.dark_mode, 
            u.translation_id, 
            u.translation_name,
            (
                SELECT COUNT(DISTINCT mutual_friend_id)
                FROM (
                    SELECT f1.friend_id AS mutual_friend_id
                    FROM friends f1
                    WHERE f1.status = 'accepted' 
                    AND f1.user_id = u.user_id 
                    AND f1.friend_id IN (
                        SELECT f2.friend_id 
                        FROM friends f2
                        WHERE f2.status = 'accepted'
                        AND f2.user_id = $1
                    )
                    
                    UNION
                    
                    SELECT f1.user_id AS mutual_friend_id
                    FROM friends f1
                    WHERE f1.status = 'accepted' 
                    AND f1.friend_id = u.user_id 
                    AND f1.user_id IN (
                        SELECT f2.friend_id 
                        FROM friends f2
                        WHERE f2.status = 'accepted'
                        AND f2.user_id = $1
                    )
                    
                    UNION
                    
                    SELECT f1.friend_id AS mutual_friend_id
                    FROM friends f1
                    WHERE f1.status = 'accepted'
                    AND f1.user_id = u.user_id 
                    AND f1.friend_id IN (
                        SELECT f2.user_id 
                        FROM friends f2
                        WHERE f2.status = 'accepted'
                        AND f2.friend_id = $1
                    )
                    
                    UNION
                    
                    SELECT f1.user_id AS mutual_friend_id
                    FROM friends f1
                    WHERE f1.status = 'accepted'
                    AND f1.friend_id = u.user_id 
                    AND f1.user_id IN (
                        SELECT f2.user_id 
                        FROM friends f2
                        WHERE f2.status = 'accepted'
                        AND f2.friend_id = $1
                    )
                ) AS mutual_friends
            ) AS mutual_friends,
            (
                SELECT COUNT(*)
                FROM likes
                WHERE likes.user_id = u.user_id
            ) AS total_like_count
        FROM users u
        WHERE u.public_profile = true 
            AND u.user_id NOT IN (
                SELECT unnest($2::int[])
            )
    `, userIDUint, pq.Array(excludedUserIDs)).Scan(&suggestedFriends)

	c.JSON(http.StatusOK, suggestedFriends)
}

func listFriendRequests(c *gin.Context) {
	userID := c.MustGet("userID").(uint)

	var friendRequests []struct {
		UserID   uint   `json:"user_id"`
		Username string `json:"username"`
	}

	err := db.Raw(`
		SELECT 
			u.user_id, 
			u.username
		FROM users u
		JOIN friends f ON (
			(f.friend_id = u.user_id AND f.user_id = ?) OR 
			(f.user_id = u.user_id AND f.friend_id = ?)
		)
		WHERE 
			(f.friend_id = ? AND f.status = 'requested')
	`, userID, userID, userID).Scan(&friendRequests).Error

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
	// Convert the email to lowercase for case-insensitive comparison
	emailLower := strings.ToLower(req.Email)
	if err := db.First(&user, "LOWER(email) = ?", emailLower).Error; err != nil {
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
	userID := c.MustGet("userID").(uint) // Get current user ID
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

	var verses []struct {
		UserVerse
		Username string `json:"username"`
	}
	offset := (pageInt - 1) * pageSizeInt

	err = db.Raw(`
		SELECT uv.*, u.username 
		FROM user_verses uv
		JOIN users u ON u.user_id = uv.user_id
		LEFT JOIN friends f ON (
			(f.user_id = u.user_id AND f.friend_id = ?) OR 
			(f.friend_id = u.user_id AND f.user_id = ?)
		)
		WHERE uv.is_published = true AND (
			u.user_id = ? OR 
			u.public_profile = true OR 
			f.status = 'accepted'
		)
		ORDER BY uv.user_verse_id DESC
		LIMIT ? OFFSET ?
	`, userID, userID, userID, pageSizeInt, offset).Scan(&verses).Error

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("Failed to retrieve verses: %v", err)})
		return
	}

	c.JSON(http.StatusOK, verses)
}

func publishVerse(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	verseID := c.Param("id")

	var req struct {
		IsPublished bool `json:"is_published"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	var verse UserVerse
	if err := db.First(&verse, "user_verse_id = ? AND user_id = ?", verseID, userID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Verse not found or you don't have permission to update this verse"})
		return
	}

	verse.IsPublished = req.IsPublished
	if err := db.Save(&verse).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update verse publication status"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Verse publication status updated successfully"})
}

func unpublishVerse(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	verseID := c.Param("id")

	var verse UserVerse
	if err := db.First(&verse, "user_verse_id = ? AND user_id = ?", verseID, userID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Verse not found or you don't have permission to update this verse"})
		return
	}

	verse.IsPublished = false
	if err := db.Save(&verse).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update verse publication status"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Verse unpublished successfully"})
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
	if err := db.Select("user_verse_id, verse_id, content, note, is_published"). // Include is_published
											Where("user_id = ?", userID).Offset(offset).Limit(pageSizeInt).Find(&verses).Error; err != nil {
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

func getCommentRequests(c *gin.Context) {
	userID := c.MustGet("userID").(uint)

	var notifications []Notification
	if err := db.Where("user_id = ?", userID).Find(&notifications).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to retrieve comment requests"})
		return
	}

	c.JSON(http.StatusOK, notifications)
}

func addComment(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	userVerseIDStr := c.Param("id")
	userVerseID, err := strconv.Atoi(userVerseIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid UserVerse ID"})
		return
	}

	var comment Comment
	if err := c.ShouldBindJSON(&comment); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	comment.UserID = userID
	comment.UserVerseID = userVerseID

	// Handle ParentCommentID
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
	if err := db.First(&user, userID).Error; err == nil {
		comment.Username = user.Username
	}

	// Save the comment to the database
	if err := db.Create(&comment).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create comment"})
		return
	}

	// Notification logic
	var notification Notification
	if comment.ParentCommentID != nil {
		// Reply to a comment, notify the owner of the parent comment
		var parentComment Comment
		if err := db.First(&parentComment, *comment.ParentCommentID).Error; err == nil {
			notification = Notification{
				UserID:      parentComment.UserID,
				Content:     "You have a new reply on your comment.",
				CommentID:   &comment.CommentID,
				UserVerseID: parentComment.UserVerseID,
			}
		}
	} else {
		// New comment on UserVerse, notify the owner of the UserVerse
		var userVerse UserVerse
		if err := db.First(&userVerse, userVerseID).Error; err == nil {
			notification = Notification{
				UserID:      userVerse.UserID,
				Content:     "You have a new comment on your verse.",
				CommentID:   &comment.CommentID,
				UserVerseID: int(userVerse.UserVerseID),
			}
		}
	}

	// Save the notification to the database
	if err := db.Create(&notification).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create notification"})
		return
	}

	c.JSON(http.StatusOK, comment)
}

// func addComment(c *gin.Context) {
// 	userID := c.MustGet("userID").(uint)
// 	userVerseID := c.Param("id")

// 	var comment Comment
// 	if err := c.ShouldBindJSON(&comment); err != nil {
// 		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
// 		return
// 	}
// 	comment.UserID = userID
// 	comment.UserVerseID, _ = strconv.Atoi(userVerseID)

// 	parentCommentIDStr := c.Query("parentCommentID")
// 	if parentCommentIDStr != "" {
// 		parentCommentID, err := strconv.Atoi(parentCommentIDStr)
// 		if err == nil {
// 			parentCommentIDUint := uint(parentCommentID)
// 			comment.ParentCommentID = &parentCommentIDUint
// 		}
// 	}

// 	// Fetch username of the commenter
// 	var user User
// 	if err := db.First(&user, "user_id = ?", userID).Error; err == nil {
// 		comment.Username = user.Username
// 	}

// 	db.Create(&comment)
// 	c.JSON(http.StatusOK, comment)
// }

func updateComment(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	commentID := c.Param("commentID")

	var existingComment Comment
	if err := db.First(&existingComment, "comment_id = ? AND user_id = ?", commentID, userID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Comment not found"})
		return
	}

	var updatedComment Comment
	if err := c.ShouldBindJSON(&updatedComment); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	existingComment.Content = updatedComment.Content
	db.Save(&existingComment)

	c.JSON(http.StatusOK, existingComment)
}

func deleteComment(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	commentID := c.Param("commentID")

	var existingComment Comment
	if err := db.First(&existingComment, "comment_id = ? AND user_id = ?", commentID, userID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Comment not found"})
		return
	}

	// Anonymize and redact the comment
	existingComment.Username = "redacted"
	existingComment.Content = ""
	existingComment.UserID = 0

	db.Save(&existingComment)
	c.JSON(http.StatusOK, gin.H{"message": "Comment deleted and anonymized"})
}

func getComments(c *gin.Context) {
	userVerseID := c.Param("id")

	var comments []Comment

	// Use left join to include comments with userID = 0
	err := db.Raw(`
		SELECT comments.*, 
		       CASE 
		         WHEN users.user_id IS NULL THEN 'redacted'
		         ELSE users.username 
		       END AS username 
		FROM comments
		LEFT JOIN users ON users.user_id = comments.user_id
		WHERE comments.user_verse_id = ?`, userVerseID).Scan(&comments).Error

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Handle case where comment's user_id is 0 by setting username to 'redacted'
	for i, comment := range comments {
		if comment.UserID == 0 {
			comments[i].Username = "redacted"
		}
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
