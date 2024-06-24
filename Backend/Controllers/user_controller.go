package Controllers

import (
	"log"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"

	"yourproject/Models"
)

var DB *gorm.DB

func CreateAdminUser() {
	var user Models.User
	if err := DB.First(&user, "email = ?", "admin@example.com").Error; err == nil {
		return
	}

	passwordHash, _ := bcrypt.GenerateFromPassword([]byte("adminpassword"), bcrypt.DefaultCost)
	admin := Models.User{
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
	DB.Create(&admin)
	log.Println("Admin user created or already exists.")
}

func RegisterUser(c *gin.Context) {
	var req Models.RegistrationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	passwordHash, _ := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	user := Models.User{
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

	if err := DB.Create(&user).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "User registered successfully"})
}

func LoginUser(c *gin.Context) {
	var req Models.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var user Models.User
	if err := DB.First(&user, "email = ?", req.Email).Error; err != nil {
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
