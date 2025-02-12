import { FC, useEffect } from 'react';
import { useLoaderData, useParams } from 'react-router';
import { useAppStore } from '~/store/app';

export interface PageProps {
  children?: JSX.Element;
  title: string;
}

/*
 * Wrapper for Route components to update page title
 */
const Page: FC<PageProps> = ({ children, title }) => {
  const testSuites = useAppStore((state) => state.testSuites);
  const loadedChildren = useLoaderData() as JSX.Element;
  const params = useParams();

  // Handle options-specific title population
  if (title.toLowerCase() === 'options') {
    const suiteId: string = params.test_suite_id || '';
    const suite = testSuites.find((suite) => suite.id === suiteId);
    const suiteName = suite?.short_title || suite?.title;
    const titlePrepend = suiteName ? `${suiteName}` : 'Suite';
    title = `${titlePrepend} ${title}`;
  }

  useEffect(() => {
    document.title = title || '';
  }, [title]);

  return children || loadedChildren;
};

export default Page;
