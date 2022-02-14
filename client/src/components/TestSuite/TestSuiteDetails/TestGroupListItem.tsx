import React, { FC } from 'react';
import useStyles from './styles';
import {
  Accordion,
  AccordionDetails,
  AccordionSummary,
  Divider,
  ListItem,
  ListItemText,
  Typography,
} from '@mui/material';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import { RunnableType, TestGroup } from 'models/testSuiteModels';
import ResultIcon from './ResultIcon';
import TestRunButton from '../TestRunButton/TestRunButton';

interface TestGroupListItemProps {
  testGroup: TestGroup;
  runTests: (runnableType: RunnableType, runnableId: string) => void;
  testRunInProgress: boolean;
}

const TestGroupListItem: FC<TestGroupListItemProps> = ({
  testGroup,
  runTests,
  testRunInProgress,
}) => {
  const styles = useStyles();

  return (
    <Accordion disableGutters>
      <AccordionSummary
        expandIcon={<ExpandMoreIcon />}
        aria-controls="panel1a-content"
        id="panel1a-header"
      >
        <ListItem className={styles.testGroupCardList}>
          <ListItemText primary={testGroup.title} secondary={testGroup.result?.result_message} />
          <div className={styles.testIcon}>{<ResultIcon result={testGroup.result} />}</div>
          <TestRunButton
            runnable={testGroup}
            runnableType={RunnableType.TestGroup}
            runTests={runTests}
            testRunInProgress={testRunInProgress}
          />
        </ListItem>
      </AccordionSummary>
      <Divider />
      <AccordionDetails>
        <Typography></Typography>
      </AccordionDetails>
    </Accordion>
  );
};

export default TestGroupListItem;
