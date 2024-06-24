package Models

import (
	"gorm.io/gorm"
)

type UserVerse struct {
	gorm.Model
	UserVerseID uint   `gorm:"primaryKey"`
	VerseID     string `gorm:"not null"`
	Content     string `gorm:"type:text"`
	Verse       string `gorm:"type:text"`
	UserID      uint   `gorm:"not null"`
	Note        string `gorm:"type:text"`
}

type Like struct {
	gorm.Model
	LikeID      uint `gorm:"primaryKey"`
	UserID      uint `gorm:"not null"`
	UserVerseID int  `gorm:"not null"`
}

type Comment struct {
	gorm.Model
	CommentID       uint   `gorm:"primaryKey"`
	Content         string `gorm:"type:text;not null"`
	UserID          uint   `gorm:"not null"`
	Username        string `gorm:"not null"`
	VerseID         string `gorm:"not null"`
	ParentCommentID *uint
}
