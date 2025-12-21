import React from 'react';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';

interface RulesPageProps {
  content: string;
}

export default function RulesPage({ content }: RulesPageProps) {
  return (
    <div className="max-w-4xl mx-auto">
      <article
        className="prose prose-invert prose-slate max-w-none 
        prose-headings:text-amber-500 prose-a:text-blue-400 hover:prose-a:text-blue-300
        prose-strong:text-slate-200 prose-code:text-amber-200 prose-code:bg-slate-800 prose-code:px-1 prose-code:rounded
        prose-th:text-slate-300 prose-td:text-slate-400"
      >
        <ReactMarkdown remarkPlugins={[remarkGfm]}>{content}</ReactMarkdown>
      </article>
    </div>
  );
}
