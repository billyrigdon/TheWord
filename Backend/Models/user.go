package Models

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
