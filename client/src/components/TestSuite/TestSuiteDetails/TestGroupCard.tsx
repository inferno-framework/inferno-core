import React, { FC } from 'react';
import { useLocation } from 'react-router-dom';
import useStyles from './styles';
import { TestGroup, RunnableType, TestSuite } from 'models/testSuiteModels';
import { Box, Breadcrumbs, Card, Link, List, Typography } from '@mui/material';
import NavigateNextIcon from '@mui/icons-material/NavigateNext';
import ReactMarkdown from 'react-markdown';
import ResultIcon from './ResultIcon';
import TestRunButton from '../TestRunButton/TestRunButton';

interface TestGroupCardProps {
  runnable: TestSuite | TestGroup;
  runTests: (runnableType: RunnableType, runnableId: string) => void;
  testRunInProgress: boolean;
}

const TestGroupCard: FC<TestGroupCardProps> = ({
  runnable,
  runTests,
  children,
  testRunInProgress,
}) => {
  const styles = useStyles();
  const location = useLocation();

  const populateBreadcrumbs = () => {
    if ('parent_group' in runnable) {
      return [
        <Link
          underline="hover"
          key="1"
          color="inherit"
          href={`${location.pathname}#${runnable.parent_group?.id as string}`}
        >
          {runnable.parent_group?.short_title || runnable.parent_group?.title || ''}
        </Link>,
        <Typography key="2" color="text.primary" className={styles.currentItem}>
          {runnable.title}
        </Typography>,
      ];
    }
    return [
      <Typography key="1" color="text.primary" className={styles.currentItem}>
        {runnable.title}
      </Typography>,
    ];
  };

  const buttonText = runnable.run_as_group ? 'Run Tests' : 'Run All Tests';

  const description =
    runnable.description && runnable.description.length > 0 ? (
      <div>
        <ReactMarkdown>{runnable.description}</ReactMarkdown>
      </div>
    ) : null;

  return (
    <Card className={styles.testGroupCard} variant="outlined">
      <div className={styles.testGroupCardHeader}>
        <span className={styles.testGroupCardHeaderResult}>
          <ResultIcon result={runnable.result} />
        </span>
        <span className={styles.testGroupCardHeaderText}>
          <Breadcrumbs separator={<NavigateNextIcon fontSize="small" />} aria-label="breadcrumb">
            {populateBreadcrumbs()}
          </Breadcrumbs>
        </span>
        <TestRunButton
          buttonText={buttonText}
          runnable={runnable}
          runTests={runTests}
          testRunInProgress={testRunInProgress}
        />
      </div>
      {description && <Box margin="20px">{description}</Box>}
      <List className={styles.testGroupCardList}>{children}</List>
    </Card>
  );
};

export default TestGroupCard;
