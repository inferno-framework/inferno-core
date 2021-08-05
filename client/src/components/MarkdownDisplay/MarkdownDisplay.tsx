import React, { FC } from 'react';
import ReactMarkdown from 'react-markdown';

type MarkdownDisplayProps = {
  markdown: string;
};

const MardownDisplay: FC<MarkdownDisplayProps> = ({ markdown }) => {
  const cleanedMarkdown = markdown
    .split('\n')
    .map((line) => line.trim())
    .join('\n');
  return <ReactMarkdown>{cleanedMarkdown}</ReactMarkdown>;
};

export default MardownDisplay;
