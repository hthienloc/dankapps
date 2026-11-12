package main

import (
	"context"
	"fmt"

	"github.com/duxlabs-dev/dux-go/ipc"
	"github.com/duxlabs-dev/dux-go/log"
	"github.com/duxlabs-dev/dux-go/shellapp"
)

type dankBackend struct {
	srv *ipc.Server
}

func (b *dankBackend) SocketPath() string { return b.srv.SocketPath() }
func (b *dankBackend) Close()             { b.srv.Close() }

func bootBackend(ctx context.Context) (shellapp.Backend, error) {
	var srv *ipc.Server

	handler := func(ctx context.Context, w *ipc.ConnWriter, req ipc.Request, sub *ipc.Subscriber) {
		switch req.Method {
		case "ui.show":
			view, _ := req.Params["view"].(string)
			srv.Bus().Publish("ui.action", map[string]any{"action": "show", "view": view})
			w.Respond(req.ID, map[string]any{"ok": true})
		case "ui.toggle":
			view, _ := req.Params["view"].(string)
			srv.Bus().Publish("ui.action", map[string]any{"action": "toggle", "view": view})
			w.Respond(req.ID, map[string]any{"ok": true})
		case "ping":
			w.Respond(req.ID, map[string]any{"pong": true})
		default:
			w.RespondError(req.ID, "unknown method: "+req.Method)
		}
	}

	srv = ipc.NewServer(ipc.Config{
		AppName:      "dankclock",
		APIVersion:   1,
		Capabilities: []string{"ui.show", "ui.toggle"},
	}, handler)

	if err := srv.Listen(); err != nil {
		return nil, fmt.Errorf("listen ipc: %w", err)
	}

	log.Infof("ipc listening on %s", srv.SocketPath())
	return &dankBackend{srv: srv}, nil
}
