import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import { CardComponent } from './Card';
import { CoreCard, ItemCard } from '../types';

describe('CardComponent', () => {
  const mockCoreCard: CoreCard = {
    type: 'core',
    id: 'c1',
    name: 'Strike',
    stats: { red: 2, yellow: 0, blue: 0 },
    cost: 1,
    rules: [
      { 
        type: 'attack', 
        data: { 
          power: { source: 'Red', modifier: 0 }, 
          resistedBy: 'Red',
          effect: [{ type: 'textRun', content: 'Hit them', style: undefined }] 
        } 
      }
    ],
    flavor: [{ type: 'textRun', content: 'A simple strike.', style: 'Italic' }]
  };

  const mockItemCard: ItemCard = {
    type: 'item',
    id: 'i1',
    name: 'Sword',
    traits: ['Sharp'],
    weight: 1,
    value: 10,
    defense: 1,
    resilience: 0,
    flavor: [{ type: 'textRun', content: 'A sharp sword.', style: 'Italic' }]
  };

  it('renders CoreCard details', () => {
    render(<CardComponent card={mockCoreCard} />);
    expect(screen.getByText('Strike')).toBeInTheDocument();
    expect(screen.getByText('A simple strike.')).toBeInTheDocument();
    // Check stats rendering (Red: 2)
    // The component renders stats in a specific way, maybe check for text content or structure
    // It renders "2" inside a red box/icon
    expect(screen.getByText('2')).toBeInTheDocument();
    // Check cost rendering
    expect(screen.getByText('Cost')).toBeInTheDocument();
    expect(screen.getByText('1')).toBeInTheDocument();
  });

  it('renders ItemCard details', () => {
    render(<CardComponent card={mockItemCard} />);
    expect(screen.getByText('Sword')).toBeInTheDocument();
    expect(screen.getByText('A sharp sword.')).toBeInTheDocument();
    expect(screen.getByText('Sharp')).toBeInTheDocument();
  });

  it('handles click events', () => {
    const handleClick = vi.fn();
    render(<CardComponent card={mockCoreCard} onClick={handleClick} />);
    fireEvent.click(screen.getByText('Strike'));
    expect(handleClick).toHaveBeenCalledTimes(1);
  });

  it('shows selection state', () => {
    const { container } = render(<CardComponent card={mockCoreCard} selected={true} />);
    // Selection usually adds a border or class
    // In Card.tsx: border-yellow-400
    const cardDiv = container.firstChild;
    expect(cardDiv).toHaveClass('border-yellow-500');
  });
});
