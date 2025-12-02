import React, { createContext, useContext, useEffect, useRef, useState } from 'react';
import { z } from 'zod';
import { BroadcastActionSchema } from '../types/sync';
import { BroadcastAction } from '../types/sync';

// Types for messages
type ClientMessage = { tag: 'Join'; name: string } | { tag: 'Broadcast'; payload: BroadcastAction };

type ServerMessage =
  | { tag: 'Welcome'; yourClientId: string; connectedClients: string[]; history: BroadcastAction[] }
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

  // Define ServerMessage Schema
  const ServerMessageSchema = z.discriminatedUnion('tag', [
    z.object({
      tag: z.literal('Welcome'),
      yourClientId: z.string(),
      connectedClients: z.array(z.string()),
      history: z.array(BroadcastActionSchema),
    }),
    z.object({
      tag: z.literal('BroadcastMessage'),
      fromClientId: z.string(),
      payload: BroadcastActionSchema,
    }),
    z.object({
      tag: z.literal('ClientJoined'),
      newClientName: z.string(),
      newClientId: z.string(),
    }),
    z.object({ tag: z.literal('ClientLeft'), leftClientId: z.string() }),
    z.object({ tag: z.literal('ErrorMessage'), error: z.string() }),
  ]);

  // ... (inside component)

  const handleMessage = (msg: unknown) => {
    // Basic normalization if needed
    let normalized: unknown = msg;

    const raw = msg as {
      tag?: string;
      Welcome?: { yourClientId: string; connectedClients: string[] };
    };

    // Legacy/Default Aeson normalization
    if (raw.Welcome && !raw.tag) {
      normalized = {
        tag: 'Welcome',
        yourClientId: raw.Welcome.yourClientId,
        connectedClients: raw.Welcome.connectedClients,
        history: [], // Legacy fallback if history is missing
      };
    }

    const result = ServerMessageSchema.safeParse(normalized);

    if (result.success) {
      const message = result.data;
      setLastMessage(message);
      switch (message.tag) {
        case 'Welcome':
          setClientId(message.yourClientId);
          setConnectedClients(message.connectedClients);
          break;
        case 'ClientJoined':
          setConnectedClients((prev) => [...prev, message.newClientName]);
          break;
        case 'ClientLeft':
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
