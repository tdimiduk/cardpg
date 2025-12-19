import React, { createContext, useContext, useEffect, useRef, useState } from 'react';
import { serverMessageSchema } from '../generated/types.zod';
import { ClientMessage, ServerMessage } from '../generated/types';

interface WebSocketContextType {
  isConnected: boolean;
  clientId: string | null;
  connectedClients: string[];
  sendMessage: (msg: ClientMessage) => void;
  subscribe: (callback: (msg: ServerMessage) => void) => () => void;
}

const WebSocketContext = createContext<WebSocketContextType | null>(null);

export const WebSocketProvider: React.FC<{ children: React.ReactNode; url?: string }> = ({
  children,
  url,
}) => {
  const [isConnected, setIsConnected] = useState(false);
  const [clientId, setClientId] = useState<string | null>(null);
  const [connectedClients, setConnectedClients] = useState<string[]>([]);

  // Listeners
  const listenersRef = useRef<Set<(msg: ServerMessage) => void>>(new Set());

  const ws = useRef<WebSocket | null>(null);

  useEffect(() => {
    // Connect to local server
    // Determine WebSocket URL based on current location
    let wsUrl = url;
    if (!wsUrl) {
      const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
      const host = window.location.host;
      wsUrl = `${protocol}//${host}/api`;
    }

    // Attach Client ID and Name if known
    const storedId = localStorage.getItem('cardpg_client_id');
    const storedName = localStorage.getItem('cardpg_client_name');

    // Build query params
    const params = new URLSearchParams();
    if (storedId) params.append('clientId', storedId);
    if (storedName) params.append('name', storedName);

    const queryString = params.toString();
    if (queryString) {
      wsUrl += `?${queryString}`;
    }

    const socket = new WebSocket(wsUrl);
    ws.current = socket;

    socket.onopen = () => {
      console.log('Connected to WebSocket server');
      setIsConnected(true);
      // We still send Join to set the name, but ID is handled by handshake now.
      let name = localStorage.getItem('cardpg_client_name');
      if (!name) {
        name = 'Player-' + Math.floor(Math.random() * 1000);
        localStorage.setItem('cardpg_client_name', name);
      }

      sendMessage({
        type: 'join',
        name,
        // ID is now handled by connection query param
        id: undefined,
      });
    };

    socket.onclose = (event) => {
      console.log('Disconnected from WebSocket server:', {
        code: event.code,
        reason: event.reason,
        wasClean: event.wasClean,
      });
      setIsConnected(false);
    };

    socket.onerror = (error) => {
      console.error('WebSocket Error:', error);
    };

    socket.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data);
        console.log('Received:', data);
        handleMessage(data);
      } catch (e) {
        console.error('Failed to parse message', e);
      }
    };

    return () => {
      socket.close();
    };
  }, []);

  const handleMessage = (msg: unknown) => {
    const result = serverMessageSchema.safeParse(msg);

    if (result.success) {
      const message = result.data;

      // Notify Listeners
      listenersRef.current.forEach((callback) => {
        try {
          callback(message);
        } catch (e) {
          console.error('Error in WebSocket listener:', e);
        }
      });

      // Internal State Updates
      switch (message.type) {
        case 'welcome':
          setClientId(message.yourClientId);
          localStorage.setItem('cardpg_client_id', message.yourClientId);
          setConnectedClients(message.connectedClients);
          break;
        case 'clientJoined':
          setConnectedClients((prev) => [...prev, message.newClientName]);
          break;
        case 'clientLeft':
          // We don't have the name here easily unless we track a map.
          break;
      }
    } else {
      console.error('Failed to parse server message:', result.error);
    }
  };

  const sendMessage = (msg: ClientMessage) => {
    if (ws.current && ws.current.readyState === WebSocket.OPEN) {
      // We configured Haskell to use TaggedObject, so we can send the object directly
      // as it already has the 'tag' property.
      console.log('[WebSocket] Sending:', msg);
      ws.current.send(JSON.stringify(msg));
    } else {
      console.warn('[WebSocket] Cannot send message, socket not open:', {
        readyState: ws.current?.readyState,
        msg,
      });
    }
  };

  const subscribe = (callback: (msg: ServerMessage) => void) => {
    listenersRef.current.add(callback);
    return () => {
      listenersRef.current.delete(callback);
    };
  };

  return (
    <WebSocketContext.Provider
      value={{ isConnected, clientId, connectedClients, sendMessage, subscribe }}
    >
      {children}
    </WebSocketContext.Provider>
  );
};

export const useWebSocket = () => {
  const context = useContext(WebSocketContext);
  if (!context) {
    throw new Error('useWebSocket must be used within a WebSocketProvider');
  }
  return context;
};
