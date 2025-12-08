import React, { createContext, useContext, useEffect, useRef, useState } from 'react';
import { serverMessageSchema, ClientMessage, ServerMessage } from '../types';

interface WebSocketContextType {
  isConnected: boolean;
  clientId: string | null;
  connectedClients: string[];
  sendMessage: (msg: ClientMessage) => void;
  lastMessage: ServerMessage | null;
}

const WebSocketContext = createContext<WebSocketContextType | null>(null);

export const WebSocketProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [isConnected, setIsConnected] = useState(false);
  const [clientId, setClientId] = useState<string | null>(null);
  const [connectedClients, setConnectedClients] = useState<string[]>([]);
  const [lastMessage, setLastMessage] = useState<ServerMessage | null>(null);
  const ws = useRef<WebSocket | null>(null);

  useEffect(() => {
    // Connect to local server
    // Determine WebSocket URL based on current location
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    const host = window.location.host;
    // If in development (localhost:5173), connect to localhost:8080
    // Otherwise (production), connect to /api on the same host
    const wsUrl = host.includes('localhost') ? 'ws://localhost:8080' : `${protocol}//${host}/api`;

    const socket = new WebSocket(wsUrl);
    ws.current = socket;

    socket.onopen = () => {
      console.log('Connected to WebSocket server');
      setIsConnected(true);
      // Auto-join for now
      sendMessage({ type: 'join', name: 'Player-' + Math.floor(Math.random() * 1000) });
    };

    socket.onclose = () => {
      console.log('Disconnected from WebSocket server');
      setIsConnected(false);
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
      setLastMessage(message);
      switch (message.type) {
        case 'welcome':
          setClientId(message.yourClientId);
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
      ws.current.send(JSON.stringify(msg));
    }
  };

  return (
    <WebSocketContext.Provider
      value={{ isConnected, clientId, connectedClients, sendMessage, lastMessage }}
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
