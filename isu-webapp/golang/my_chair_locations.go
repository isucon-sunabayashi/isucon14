package main

import (
	cmap "github.com/orcaman/concurrent-map/v2"
	"log/slog"
)

var (
	chairLocationCacheById      = cmap.New[*ChairLocation]()
	chairLocationCacheByChairId = cmap.New[*ChairLocation]()
)

// Initialize関数に記載
//
// ChairLocationをchairLocationCacheByIdに突っ込む
// ChairLocationをchairLocationCacheByChairIdに突っ込む
// 初期値: 2109件
func initializeChairLocationCache() {
	var chairLocations []*ChairLocation
	if err := db.Select(&chairLocations, "SELECT * FROM chair_locations;"); err != nil {
		slog.Error("chair_location一覧取得に失敗", err)
		return
	}
	chairLocationCacheById.Clear()
	chairLocationCacheByChairId.Clear()
	for _, chairLocation := range chairLocations {
		setChairLocationCache(chairLocation)
	}
}

// キャッシュする
func setChairLocationCache(chairLocation *ChairLocation) {
	chairLocationCacheById.Set(chairLocation.ID, chairLocation)
	chairLocationCacheByChairId.Set(chairLocation.ChairID, chairLocation)
}

// キャッシュから取得
func getChairLocationById(id string) *ChairLocation {
	if chairLocation, ok := chairLocationCacheById.Get(id); ok {
		return chairLocation
	} else {
		return nil
	}
}

// キャッシュから取得
func getChairLocationByChairId(chairId string) *ChairLocation {
	if chairLocation, ok := chairLocationCacheByChairId.Get(chairId); ok {
		return chairLocation
	} else {
		return nil
	}
}
