import { FC, useEffect } from 'react';

export interface PageProps {
  children: JSX.Element;
  title: string;
}

/*
 * Wrapper for Route components to update page title
 */
const Page: FC<PageProps> = ({ children, title }) => {
  useEffect(() => {
    document.title = title || '';
  }, [title]);

  return children;
};

export default Page;
