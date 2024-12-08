package main

import (
	"database/sql"
	cmap "github.com/orcaman/concurrent-map/v2"
	"log/slog"
	"math"
	"strings"
)

type ChairLocationDistanceSumInfo struct {
	ChairID                string
	TotalDistance          int
	TotalDistanceUpdatedAt sql.NullTime
}

var (
	chairLocationCacheById                     = cmap.New[*ChairLocation]()
	chairLocationDistanceSumInfoCacheByChairId = cmap.New[ChairLocationDistanceSumInfo]()
	chairLocationsCacheByChairId               = cmap.New[[]*ChairLocation]()
)

// Initialize関数に記載
//
// ChairLocationをchairLocationCacheByIdに突っ込む
// ChairLocationをchairLocationCacheByChairIdに突っ込む
// 初期値: 2109件
func initializeChairLocationCache() {
	var chairLocations []*ChairLocation
	if err := db.Select(&chairLocations, "SELECT * FROM chair_locations ORDER BY created_at ASC;"); err != nil {
		slog.Error("chair_location一覧取得に失敗", err)
		return
	}
	chairLocationCacheById.Clear()
	chairLocationDistanceSumInfoCacheByChairId.Clear()
	chairLocationsCacheByChairId.Clear()

	for _, chairLocation := range chairLocations {
		setChairLocationCacheForInitialize(chairLocation)
	}

	for _, list := range chairLocationsCacheByChairId.Items() {
		updateChairLocationDistanceSumInfoByChairId(list)
	}
}

// キャッシュする
func setChairLocationCacheForInitialize(chairLocation *ChairLocation) {
	chairLocationCacheById.Set(strings.ToUpper(chairLocation.ID), chairLocation)

	if list := getChairLocationsByChairId(strings.ToUpper(chairLocation.ChairID)); list == nil {
		list = []*ChairLocation{}
		list = append(list, chairLocation)
		chairLocationsCacheByChairId.Set(strings.ToUpper(chairLocation.ChairID), list)
	} else {
		list = append(list, chairLocation)
		chairLocationsCacheByChairId.Set(strings.ToUpper(chairLocation.ChairID), list)
	}
}

func setChairLocationCache(chairLocation *ChairLocation) {
	chairLocationCacheById.Set(strings.ToUpper(chairLocation.ID), chairLocation)

	if list := getChairLocationsByChairId(strings.ToUpper(chairLocation.ChairID)); list == nil {
		list = []*ChairLocation{}
		list = append(list, chairLocation)
		chairLocationsCacheByChairId.Set(strings.ToUpper(chairLocation.ChairID), list)
		updateChairLocationDistanceSumInfoByChairId(list)
	} else {
		list = append(list, chairLocation)
		chairLocationsCacheByChairId.Set(strings.ToUpper(chairLocation.ChairID), list)
		updateChairLocationDistanceSumInfoByChairId(list)
	}
}

// LEFT JOIN (SELECT chair_id,
//
//	       SUM(IFNULL(distance, 0)) AS total_distance,
//	       MAX(created_at)          AS total_distance_updated_at
//	FROM (SELECT chair_id,
//	             created_at,
//	             ABS(latitude - LAG(latitude) OVER (PARTITION BY chair_id ORDER BY created_at)) +
//	             ABS(longitude - LAG(longitude) OVER (PARTITION BY chair_id ORDER BY created_at)) AS distance
//	      FROM chair_locations) tmp
//	GROUP BY chair_id) distance_table ON distance_table.chair_id = chairs.id
func updateChairLocationDistanceSumInfoByChairId(list []*ChairLocation) {
	var chairLocationDistanceSumInfo ChairLocationDistanceSumInfo
	var prev *ChairLocation
	for i, current := range list {
		if i == 0 {
			chairLocationDistanceSumInfo = ChairLocationDistanceSumInfo{
				ChairID:       (*current).ChairID,
				TotalDistance: 0,
				TotalDistanceUpdatedAt: sql.NullTime{
					Valid: false,
				},
			}
			prev = current
			continue
		}
		distance := math.Abs(float64((*current).Latitude-(*prev).Latitude)) + math.Abs(float64((*current).Longitude-(*prev).Longitude))
		// if chairLocationDistanceSumInfo.ChairID == "01JDFFT9J8JVCFVJAG4WN2B666" {
		// 	fmt.Println("-----------")
		// 	fmt.Printf("%v: %f, %f, %f, %f = %d\n",
		// 		(*current).CreatedAt,
		// 		float64((*current).Latitude),
		// 		float64((*prev).Latitude),
		// 		float64((*current).Longitude),
		// 		float64((*prev).Longitude),
		// 		int(distance),
		// 	)
		// 	fmt.Println("-----------")
		// }
		chairLocationDistanceSumInfo.TotalDistance += int(distance)
		chairLocationDistanceSumInfo.TotalDistanceUpdatedAt = sql.NullTime{
			Time:  (*current).CreatedAt,
			Valid: true,
		}
		prev = current
	}
	// if chairLocationDistanceSumInfo.ChairID == "01JDFFT9J8JVCFVJAG4WN2B666" {
	// 	fmt.Println("-----------")
	// 	fmt.Printf("debug: %+v\n", chairLocationDistanceSumInfo)
	// 	fmt.Println("-----------")
	// }
	chairLocationDistanceSumInfoCacheByChairId.Set(strings.ToUpper(chairLocationDistanceSumInfo.ChairID), chairLocationDistanceSumInfo)
}

// キャッシュから取得
func getChairLocationById(id string) *ChairLocation {
	if chairLocation, ok := chairLocationCacheById.Get(strings.ToUpper(id)); ok {
		return chairLocation
	} else {
		return nil
	}
}

// キャッシュから取得
func getLatestChairLocationByChairId(chairId string) *ChairLocation {
	if chairLocations, ok := chairLocationsCacheByChairId.Get(strings.ToUpper(chairId)); ok {
		return chairLocations[len(chairLocations)-1]
	} else {
		return nil
	}
}

// キャッシュから取得
func getChairLocationsByChairId(chairId string) []*ChairLocation {
	if chairLocations, ok := chairLocationsCacheByChairId.Get(strings.ToUpper(chairId)); ok {
		return chairLocations
	} else {
		return nil
	}
}

func getChairLocationDistanceSumInfoCacheByChairId(chairId string) ChairLocationDistanceSumInfo {
	if chairLocationDistanceSumInfo, ok := chairLocationDistanceSumInfoCacheByChairId.Get(strings.ToUpper(chairId)); ok {
		return chairLocationDistanceSumInfo
	} else {
		return ChairLocationDistanceSumInfo{
			ChairID:       chairId,
			TotalDistance: 0,
			TotalDistanceUpdatedAt: sql.NullTime{
				Valid: false,
			},
		}
	}
}
