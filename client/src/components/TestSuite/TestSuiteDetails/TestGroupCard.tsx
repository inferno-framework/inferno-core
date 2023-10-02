import React, { FC, useMemo } from 'react';
import { Box, Card, Divider, Typography } from '@mui/material';
import useStyles from './styles';
import ReactMarkdown from 'react-markdown';
import { TestGroup, RunnableType, TestSuite } from '~/models/testSuiteModels';
import InputOutputList from './TestListItem/InputOutputList';
import ResultIcon from './ResultIcon';
import TestRunButton from '~/components/TestSuite/TestRunButton/TestRunButton';
import { shouldShowDescription } from '~/components/TestSuite/TestSuiteUtilities';
import remarkGfm from 'remark-gfm';

interface TestGroupCardProps {
  children: React.ReactNode;
  runnable: TestSuite | TestGroup;
  runTests?: (runnableType: RunnableType, runnableId: string) => void;
  view: 'report' | 'run';
}

const TestGroupCard: FC<TestGroupCardProps> = ({ children, runnable, runTests, view }) => {
  const { classes } = useStyles();

  const buttonText = runnable.run_as_group ? 'Run Tests' : 'Run All Tests';

  // render markdown once on mount - it's too slow with re-rendering
  const description = useMemo(() => {
    return runnable.description ? 
      <ReactMarkdown remarkPlugins={[remarkGfm]}>{runnable.description}</ReactMarkdown> : undefined;
  }, [runnable.description]);

  const runnableType = 'tests' in runnable ? RunnableType.TestGroup : RunnableType.TestSuite;

  const renderHeader = () => {
    return (
      <Box className={classes.testGroupCardHeader}>
        {runnable.result && <ResultIcon result={runnable.result} isRunning={runnable.is_running} />}
        <span className={classes.testGroupCardHeaderText}>
          <Typography className={classes.currentItem} component="div">
            {'short_id' in runnable && (
              <Typography className={classes.shortId}>{`${runnable.short_id} `}</Typography>
            )}
            {runnable.title}
          </Typography>
        </span>
        <span className={classes.testGroupCardHeaderButton}>
          {view === 'run' && runTests && (
            <TestRunButton
              buttonText={buttonText}
              runnable={runnable}
              runnableType={runnableType}
              runTests={runTests}
            />
          )}
        </span>
      </Box>
    );
  };

  const renderDescription = () => {
    if (shouldShowDescription(runnable, description)) {
      return (
        <>
          <Box mx={2.5} overflow="auto">
            {description}
          </Box>
          <Divider />
        </>
      );
    }
  };

  const renderInputOutputs = () => {
    if ((runnable as TestGroup).user_runnable && runnable.result && runnable.run_as_group) {
      return <InputOutputList headerName="Input" inputOutputs={runnable.result?.inputs || []} />;
    }
  };

  return (
    <Card variant="outlined" sx={{ mb: 3 }}>
      {renderHeader()}
      <Divider />
      {view === 'run' && renderDescription()}
      {view === 'report' && renderInputOutputs()}
      <Box>{children}</Box>
    </Card>
  );
};

export default TestGroupCard;
