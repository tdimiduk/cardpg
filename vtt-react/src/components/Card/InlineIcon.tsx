import React from 'react';
import { Square, Circle, Diamond } from 'lucide-react';
import { ResourceType } from '../../types';

export const InlineIcon: React.FC<{ color: ResourceType }> = ({ color }) => {
  switch (color) {
    case 'Red':
      return (
        <Square
          size={12}
          className="inline text-red-600 fill-white border-red-600 align-middle mx-0.5"
          strokeWidth={3}
        />
      );
    case 'Yellow':
      return (
        <Circle
          size={12}
          className="inline text-yellow-500 fill-white border-yellow-500 align-middle mx-0.5"
          strokeWidth={3}
        />
      );
    case 'Blue':
      return (
        <Diamond
          size={12}
          className="inline text-blue-600 fill-white border-blue-600 align-middle mx-0.5"
          strokeWidth={3}
        />
      );
  }
  return null;
};
