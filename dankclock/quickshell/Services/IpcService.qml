pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services

Singleton {
    id: root

    readonly property var log: Log.scoped("IpcService")

    readonly property string socketPath: Quickshell.env("DCLOCK_SOCKET")

    property bool connected: false
    property bool subscribed: false
    property int apiVersion: 0

    property var pendingRequests: ({})
    property var topicHandlers: ({})
    property int requestCounter: 0

    signal windowActionRequested(string action, string view)

    Component.onCompleted: {
        subscribeTopic("ui.action", _onUiEvent);
        requestSocket.connected = socketPath !== "";
    }

    DSocket {
        id: requestSocket
        path: root.socketPath
        connected: false

        onConnectionStateChanged: {
            root.connected = linkUp;
            subscribeSocket.connected = false;
            if (!linkUp) {
                root._failPendingRequests("disconnected from dankclock socket");
                return;
            }
            subscribeSocket.connected = true;
        }

        parser: SplitParser {
            onRead: line => {
                if (!line || line.length === 0)
                    return;
                let response;
                try {
                    response = JSON.parse(line);
                } catch (e) {
                    root.log.warn("bad response", line.substring(0, 200));
                    return;
                }
                root._handleResponse(response);
            }
        }
    }

    DSocket {
        id: subscribeSocket
        path: root.socketPath
        connected: false

        onConnectionStateChanged: {
            root.subscribed = linkUp;
            if (linkUp)
                root._sendSubscribe(Object.keys(root.topicHandlers));
        }

        parser: SplitParser {
            onRead: line => {
                if (!line || line.length === 0)
                    return;
                let event;
                try {
                    event = JSON.parse(line);
                } catch (e) {
                    return;
                }
                root._handleEvent(event);
            }
        }
    }

    function subscribeTopic(topic, handler) {
        const handlers = topicHandlers[topic] || [];
        handlers.push(handler);
        topicHandlers[topic] = handlers;
        if (subscribed && handlers.length === 1)
            _sendSubscribe([topic]);
    }

    function _sendSubscribe(topics) {
        if (topics.length === 0)
            return;
        subscribeSocket.send({
            "id": _nextId(),
            "method": "subscribe",
            "params": {
                "topics": topics
            }
        });
    }

    function _nextId() {
        return ++requestCounter;
    }

    function _handleResponse(response) {
        const id = response.id;
        if (!id) {
            if (response.apiVersion !== undefined) {
                apiVersion = response.apiVersion;
            }
            return;
        }

        const cb = pendingRequests[id];
        if (!cb)
            return;
        delete pendingRequests[id];
        cb(response);
    }

    function _handleEvent(event) {
        const handlers = topicHandlers[event.event];
        if (!handlers)
            return;
        const data = event.data || {};
        for (const handler of handlers.slice())
            handler(data);
    }

    function _onUiEvent(data) {
        windowActionRequested(data.action || "", data.view || "");
    }

    function _failPendingRequests(reason) {
        const callbacks = pendingRequests;
        pendingRequests = ({});
        for (const id in callbacks) {
            callbacks[id]({
                "error": reason
            });
        }
    }

    function sendRequest(method, params, callback) {
        if (!connected) {
            if (callback)
                callback({
                    "error": "not connected to dankclock socket"
                });
            return;
        }

        const id = _nextId();
        const req = {
            "id": id,
            "method": method
        };
        if (params)
            req.params = params;
        if (callback)
            pendingRequests[id] = callback;
        requestSocket.send(req);
    }

    function call(method, params, callback) {
        sendRequest(method, params, callback ? response => callback(unwrap(response)) : null);
    }

    function unwrap(response) {
        if (!response.error)
            return response.result || {};
        return {
            "error": response.error,
            "code": ""
        };
    }
}
