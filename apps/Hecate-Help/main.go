package main

import (
	"github.com/wailsapp/wails/v2"
	"github.com/wailsapp/wails/v2/pkg/options"
	"github.com/wailsapp/wails/v2/pkg/options/assetserver"
)

func main() {
	app := NewApp()

	err := wails.Run(&options.App{
		Title:            "Hecate Helper",
		Width:            1200,
		Height:           800,
		AssetServer:      &assetserver.Options{Assets: assets},
		BackgroundColour: &options.RGBA{R: 15, G: 20, B: 22, A: 1},
		OnStartup:        app.startup,
		Bind:             []interface{}{app},
	})

	if err != nil {
		println("Error:", err.Error())
	}
}
