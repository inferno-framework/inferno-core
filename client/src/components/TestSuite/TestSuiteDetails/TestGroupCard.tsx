import React, { FC, useMemo } from 'react';
import { Box, Card, Divider, Link, Typography } from '@mui/material';
import { enqueueSnackbar } from 'notistack';
import Markdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import { getSingleRequirement } from '~/api/RequirementsApi';
import { TestGroup, RunnableType, TestSuite, Requirement } from '~/models/testSuiteModels';
import {
  shouldShowDescription,
  shouldShowRequirementsButton,
} from '~/components/TestSuite/TestSuiteUtilities';
import InputOutputList from '~/components/TestSuite/TestSuiteDetails/TestListItem/InputOutputList';
import RequirementsModal from '~/components/TestSuite/Requirements/RequirementsModal';
import ResultIcon from '~/components/TestSuite/TestSuiteDetails/ResultIcon';
import TestRunButton from '~/components/TestSuite/TestRunButton/TestRunButton';
import { useTestSessionStore } from '~/store/testSession';
import useStyles from './styles';

interface TestGroupCardProps {
  children: React.ReactNode;
  runnable: TestSuite | TestGroup;
  runTests?: (runnableType: RunnableType, runnableId: string) => void;
  view: 'report' | 'run';
}

const TestGroupCard: FC<TestGroupCardProps> = ({ children, runnable, runTests, view }) => {
  const { classes } = useStyles();
  const viewOnly = useTestSessionStore((state) => state.viewOnly);
  const [requirements, setRequirements] = React.useState<Requirement[]>([]);
  const [showRequirements, setShowRequirements] = React.useState(false);

  const buttonText = `${viewOnly ? 'View' : 'Run'}${runnable.run_as_group ? '' : ' All'}${viewOnly ? ' Inputs' : ' Tests'}`;

  // render markdown once on mount - it's too slow with re-rendering
  const description = useMemo(() => {
    return runnable.description ? (
      <Markdown remarkPlugins={[remarkGfm]}>{runnable.description}</Markdown>
    ) : undefined;
  }, [runnable.description]);

  const runnableType = 'tests' in runnable ? RunnableType.TestGroup : RunnableType.TestSuite;

  const showRequirementsClick = () => {
    const requirementIds = runnable.verifies_requirements;
    if (requirementIds) {
      Promise.all(requirementIds.map((requirementId) => getSingleRequirement(requirementId)))
        .then((resolvedValues) => {
          setRequirements(resolvedValues.filter((r) => !!r));
          setShowRequirements(true);
        })
        .catch((e: Error) => {
          enqueueSnackbar(`Error fetching specification requirements: ${e.message}`, {
            variant: 'error',
          });
        });
    }
  };

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
    const showDescription = shouldShowDescription(runnable, description);
    const showRequirementsButton = shouldShowRequirementsButton(runnable);
    if (showDescription || showRequirementsButton) {
      return (
        <>
          {showDescription && (
            <Box mx={2.5} overflow="auto">
              {description}
            </Box>
          )}
          {showRequirementsButton && (
            <Box display="flex" justifyContent="end" minWidth="fit-content" p={2}>
              <Link
                color="secondary"
                className={classes.textButton}
                onClick={showRequirementsClick}
              >
                View Specification Requirements
              </Link>
            </Box>
          )}
          <Divider />
          {requirements && showRequirementsButton && (
            <RequirementsModal
              requirements={requirements}
              modalVisible={showRequirements}
              hideModal={() => setShowRequirements(false)}
            />
          )}
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
    <Card variant="outlined">
      {renderHeader()}
      <Divider />
      {view === 'run' && renderDescription()}
      {view === 'report' && renderInputOutputs()}
      <Box>{children}</Box>
    </Card>
  );
};

export default TestGroupCard;
