import React, { createContext, useContext, useEffect, useRef, useState } from 'react';
import { BroadcastAction } from '../types/sync';

// Types for messages
type ClientMessage = { tag: 'Join'; name: string } | { tag: 'Broadcast'; payload: BroadcastAction };

type ServerMessage =
  | { tag: 'Welcome'; yourClientId: string; connectedClients: string[] }
  | { tag: 'BroadcastMessage'; fromClientId: string; payload: BroadcastAction }
  | { tag: 'ClientJoined'; newClientName: string; newClientId: string }
  | { tag: 'ClientLeft'; leftClientId: string }
  | { tag: 'ErrorMessage'; error: string };

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
    const socket = new WebSocket('ws://localhost:8080');
    ws.current = socket;

    socket.onopen = () => {
      console.log('Connected to WebSocket server');
      setIsConnected(true);
      // Auto-join for now
      sendMessage({ tag: 'Join', name: 'Player-' + Math.floor(Math.random() * 1000) });
    };

    socket.onclose = () => {
      console.log('Disconnected from WebSocket server');
      setIsConnected(false);
    };

    socket.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data);
        // Haskell Aeson default encoding for sum types might be object with single key
        // But let's see what we get. If we used Generic derivation it might be different.
        // Let's assume we need to normalize or it matches.
        // Wait, Aeson default for sum types is usually { "tag": "Constructor", ... } if configured,
        // or { "Constructor": { ... } } object wrapper.
        // Let's check the Haskell code... we just derived Generic.
        // Default Aeson generic encoding is { "tag": "Constructor", ... } ? No, it's usually Object with single key.
        // Actually, let's just log it first to be sure in development.
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

  const handleMessage = (msg: any) => {
    // Basic normalization if needed, for now assume we can map it
    // If Haskell sends { "tag": "Welcome", ... } great.
    // If it sends { "Welcome": { ... } } we might need to adapt.

    // Let's assume we might need to adapt for now, but I'll implement a simple handler
    // that tries to guess.

    let normalized: ServerMessage | null = null;

    // Check for Aeson default object wrapper { "Constructor": { fields } }
    // We configured Haskell to use TaggedObject "tag" "contents", so we expect { tag: "...", ... }
    if (msg.tag) {
      normalized = msg as ServerMessage;
    } else if (msg.Welcome) {
      // Fallback for legacy/default encoding if needed (though we changed server)
      normalized = { tag: 'Welcome', ...msg.Welcome };
    }

    if (normalized) {
      setLastMessage(normalized);
      switch (normalized.tag) {
        case 'Welcome':
          setClientId(normalized.yourClientId);
          setConnectedClients(normalized.connectedClients);
          break;
        case 'ClientJoined':
          setConnectedClients((prev) => [...prev, normalized.newClientName]);
          break;
        case 'ClientLeft':
          // We don't have the name here easily unless we track a map.
          break;
      }
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
