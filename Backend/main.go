package main

import (
	"fmt"
	"log"
	"os"

	"github.com/gin-gonic/gin"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"

	"TheWord/Backend/Controllers"
	"TheWord/Backend/Auth"
	"TheWords/Backend/Models"
)

var db *gorm.DB

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

	// Migrate the schema
	db.AutoMigrate(&Models.User{}, &Models.UserVerse{}, &Models.Like{}, &Models.Comment{})
	log.Println("Database tables created or already exist.")

	Auth.CreateAdminUser(db)

	r := gin.Default()

	r.POST("/register", Controllers.RegisterUser)
	r.POST("/login", Controllers.LoginUser)
	r.GET("/user/:id", Auth.AuthMiddleware, Controllers.GetUser)
	r.POST("/verse", Auth.AuthMiddleware, Controllers.CreateVerse)
	r.GET("/verse/:id", Auth.AuthMiddleware, Controllers.GetVerse)
	r.DELETE("/verses/:id", Auth.AuthMiddleware, Controllers.DeleteVerse)
	r.POST("/verse/:id/toggle-like", Auth.AuthMiddleware, Controllers.ToggleLike)
	r.POST("/verse/:id/comment", Auth.AuthMiddleware, Controllers.AddComment)
	r.GET("/user/settings", Auth.AuthMiddleware, Controllers.GetUserSettings)
	r.POST("/user/settings", Auth.AuthMiddleware, Controllers.UpdateUserSettings)
	r.GET("/verses/public", Controllers.GetPublicVerses)
	r.POST("/verses/save", Auth.AuthMiddleware, Controllers.SaveVerse)
	r.GET("/verses/saved", Auth.AuthMiddleware, Controllers.GetSavedVerses)
	r.PUT("/verses/:id", Auth.AuthMiddleware, Controllers.UpdateVerse)
	r.GET("/verse/:id/comments", Controllers.GetComments)
	r.GET("/verse/:id/likes", Controllers.GetLikesCount)

	r.Run()
}