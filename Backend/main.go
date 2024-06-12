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

type UserVerse struct {
	UserVerseID uint `gorm:"primaryKey"`
	VerseID     string
	Content     string
	Verse       string
	UserID      uint
	Note        string
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
	VerseID         string
	ParentCommentID *uint
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

	db.AutoMigrate(&User{}, &UserVerse{}, &Like{}, &Comment{})
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
	r.GET("/verses/public", getPublicVerses)
	r.POST("/verses/save", authMiddleware, saveVerse)
	r.GET("/verses/saved", authMiddleware, getSavedVerses)
	r.PUT("/verses/:id", authMiddleware, updateVerse)
	r.GET("/verse/:id/comments", getComments)
	r.GET("/verse/:id/likes", getLikesCount)

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
	err = db.Joins("JOIN users ON users.user_id = user_verses.user_id").
		Where("users.public_profile = ?", true).
		Offset(offset).
		Limit(pageSizeInt).
		Find(&verses).Error
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, verses)
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
	verseID := c.Param("id")

	var comment Comment
	if err := c.ShouldBindJSON(&comment); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	comment.UserID = userID
	comment.VerseID = verseID

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
	verseID := c.Param("id")

	var comments []Comment
	err := db.Joins("JOIN users ON users.user_id = comments.user_id").
		Where("comments.verse_id = ?", verseID).
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
