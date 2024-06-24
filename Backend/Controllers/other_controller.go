package Controllers

import (
	"log"
	"net/http"
	"strconv"
	"time"

	"github.com/dgrijalva/jwt-go"
	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

// Assuming you have a package-level variable for the DB connection
var db *gorm.DB

// Models definitions (you can import these from the Models package if needed)
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

// Handler functions
func CreateVerse(c *gin.Context) {
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

func GetVerse(c *gin.Context) {
	var verse UserVerse
	if err := db.First(&verse, "user_verse_id = ?", c.Param("id")).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Verse not found"})
		return
	}
	c.JSON(http.StatusOK, verse)
}

func DeleteVerse(c *gin.Context) {
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

func ToggleLike(c *gin.Context) {
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

func AddComment(c *gin.Context) {
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

func GetComments(c *gin.Context) {
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

func GetLikesCount(c *gin.Context) {
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
