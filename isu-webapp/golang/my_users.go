package main

import (
	cmap "github.com/orcaman/concurrent-map/v2"
	"log/slog"
	"strings"
)

var (
	userCacheById = cmap.New[*User]()
)

// Initialize関数に記載
func initializeUserCache() {
	var users []*User
	if err := db.Select(&users, "SELECT * FROM users;"); err != nil {
		slog.Error("chair_location一覧取得に失敗", err)
		return
	}
	userCacheById.Clear()

	for _, user := range users {
		setUserCache(user)
	}
}

// キャッシュする
func setUserCache(user *User) {
	userCacheById.Set(strings.ToUpper(user.ID), user)
}

// キャッシュから取得
func getUserById(id string) *User {
	if user, ok := userCacheById.Get(strings.ToUpper(id)); ok {
		return user
	} else {
		return nil
	}
}
