import React, { FC } from 'react';

export interface MetaTagsProps {
  title: string;
  description: string;
}

/* Meta tags for link unfurling */
const MetaTags: FC<MetaTagsProps> = ({ title, description }) => {
  // These tags are dynamic -- static tags are located in index.html.erb
  return (
    <>
      <title>{title}</title>
      <link rel="canonical" href={window.location.href} />
      <meta name="description" content={description} />
      <meta name="og:title" content={title} />
      <meta name="og:description" content={description} />
      <meta name="twitter:title" content={title} />
      <meta name="twitter:description" content={description} />
    </>
  );
};

export default MetaTags;
