import React from 'react';
import { render, screen } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import { RESOURCE_TYPES } from '../../constants';
import { RichTextRenderer } from './RichTextRenderer';
import { Inline } from '../../types';

describe('RichTextRenderer', () => {
  it('renders simple text', () => {
    const content: Inline[] = [{ type: 'textRun', content: 'Hello World', style: undefined }];
    render(<RichTextRenderer content={content} />);
    expect(screen.getByText('Hello World')).toBeInTheDocument();
  });

  it('renders bold text', () => {
    const content: Inline[] = [{ type: 'textRun', content: 'Bold Text', style: 'bold' }];
    render(<RichTextRenderer content={content} />);
    const el = screen.getByText('Bold Text');
    expect(el).toHaveClass('font-bold');
  });

  it('renders italic text', () => {
    const content: Inline[] = [{ type: 'textRun', content: 'Italic Text', style: 'italic' }];
    render(<RichTextRenderer content={content} />);
    const el = screen.getByText('Italic Text');
    expect(el).toHaveClass('italic');
  });

  it('renders game keywords', () => {
    const content: Inline[] = [{ type: 'textRun', content: 'Keyword', style: 'gameKeyword' }];
    render(<RichTextRenderer content={content} />);
    const el = screen.getByText('Keyword');
    expect(el).toHaveClass('font-mono');
  });

  it('renders icons/colors', () => {
    const content: Inline[] = [
      { type: 'textRun', content: 'Attack with ', style: undefined },
      { type: 'colorValue', value: { source: RESOURCE_TYPES.RED, modifier: 0 } },
    ];
    const { container } = render(<RichTextRenderer content={content} />);
    expect(screen.getByText('Attack with')).toBeInTheDocument();
    // Check for icon presence (it renders an SVG or div with specific class)
    // InlineIcon renders a lucide icon which is an SVG
    const svg = container.querySelector('svg');
    expect(svg).toBeInTheDocument();
    expect(svg).toHaveClass('text-red-600');
  });

  it('renders modifiers', () => {
    const content: Inline[] = [
      { type: 'colorValue', value: { source: RESOURCE_TYPES.BLUE, modifier: 2 } },
    ];
    render(<RichTextRenderer content={content} />);
    expect(screen.getByText('+ 2')).toBeInTheDocument();
  });

  it('renders negative modifiers', () => {
    const content: Inline[] = [
      { type: 'colorValue', value: { source: RESOURCE_TYPES.YELLOW, modifier: -1 } },
    ];
    render(<RichTextRenderer content={content} />);
    expect(screen.getByText('- 1')).toBeInTheDocument();
  });
});
