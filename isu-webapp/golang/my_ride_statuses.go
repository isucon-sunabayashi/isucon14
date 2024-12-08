package main

import (
	"fmt"
	cmap "github.com/orcaman/concurrent-map/v2"
	"log/slog"
	"strings"
	"time"
)

var (
	rideStatusCacheById       = cmap.New[*RideStatus]()
	rideStatusesCacheByRideId = cmap.New[[]*RideStatus]()
)

// Initialize関数に記載
//
// 初期値: 750件
func initializeRideStatusCache() {
	var rideStatuses []*RideStatus
	if err := db.Select(&rideStatuses, "SELECT * FROM ride_statuses ORDER BY created_at ASC;"); err != nil {
		slog.Error("ride_statuses一覧取得に失敗", err)
		return
	}
	rideStatusCacheById.Clear()
	rideStatusesCacheByRideId.Clear()

	for _, rideStatus := range rideStatuses {
		setRideStatusCacheById(rideStatus)
	}
}

// キャッシュする
func setRideStatusCacheById(rideStatus *RideStatus) {
	rideStatusCacheById.Set(strings.ToUpper(rideStatus.ID), rideStatus)
	if list := getRideStatusesByRideId(strings.ToUpper(rideStatus.RideID)); list == nil {
		list = []*RideStatus{}
		list = append(list, rideStatus)
		rideStatusesCacheByRideId.Set(strings.ToUpper(rideStatus.RideID), list)
	} else {
		list = append(list, rideStatus)
		rideStatusesCacheByRideId.Set(strings.ToUpper(rideStatus.RideID), list)
	}
}

// キャッシュから取得
func getRideStatusesByRideId(rideId string) []*RideStatus {
	if rideStatuses, ok := rideStatusesCacheByRideId.Get(strings.ToUpper(rideId)); ok {
		return rideStatuses
	} else {
		return nil
	}
}

// キャッシュから取得
func getRideStatusById(id string) *RideStatus {
	if rideStatus, ok := rideStatusCacheById.Get(strings.ToUpper(id)); ok {
		return rideStatus
	} else {
		return nil
	}
}

// update
func updateRideStatusCacheAppSentAtById(id string, appSentAt *time.Time) {
	if rideStatus := getRideStatusById(id); rideStatus != nil {
		(*rideStatus).AppSentAt = appSentAt
		return
	}
	fmt.Printf("updateRideStatusCacheAppSentAtByIdでError: %s\n", id)
}
func updateRideStatusCacheChairSentAtById(id string, chairSentAt *time.Time) {
	if rideStatus := getRideStatusById(id); rideStatus != nil {
		(*rideStatus).ChairSentAt = chairSentAt
		return
	}
	fmt.Printf("updateRideStatusCacheChairSentAtByIdでError: %s\n", id)
}
