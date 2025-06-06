import React, { FC, useEffect, useMemo } from 'react';
import { Box, Card, Divider, Link, Tabs, Typography } from '@mui/material';
import Markdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import { enqueueSnackbar } from 'notistack';
import { getSingleRequirement } from '~/api/RequirementsApi';
import {
  Message,
  Request,
  Requirement,
  Test,
  TestInput,
  TestOutput,
} from '~/models/testSuiteModels';
import {
  shouldShowDescription,
  shouldShowRequirementsButton,
} from '~/components/TestSuite/TestSuiteUtilities';
import CustomTab from '~/components/_common/CustomTab';
import CustomTooltip from '~/components/_common/CustomTooltip';
import InputOutputList from '~/components/TestSuite/TestSuiteDetails/TestListItem/InputOutputList';
import MessageList from '~/components/TestSuite/TestSuiteDetails/TestListItem/MessageList';
import RequestList from '~/components/TestSuite/TestSuiteDetails/TestListItem/RequestList';
import RequirementsModal from '~/components/TestSuite/Requirements/RequirementsModal';
import TabPanel from '~/components/TestSuite/TestSuiteDetails/TestListItem/TabPanel';
import useStyles from './styles';

interface TestRunDetailProps {
  test: Test;
  currentTabIndex: number;
  setTabIndex: React.Dispatch<React.SetStateAction<number>>;
  updateRequest?: (requestId: string, resultId: string, request: Request) => void;
  tabs: TabProps[];
}

export interface TabProps {
  label: string;
  value: Message[] | Request[] | TestInput[] | TestOutput[] | string | null | undefined;
}

const TestRunDetail: FC<TestRunDetailProps> = ({
  test,
  currentTabIndex,
  setTabIndex,
  updateRequest,
  tabs,
}) => {
  const { classes } = useStyles();
  const [requirements, setRequirements] = React.useState<Requirement[]>([]);
  const [showRequirements, setShowRequirements] = React.useState(false);

  useEffect(() => {
    setTabIndex(currentTabIndex);
  }, [currentTabIndex]);

  const testDescription: JSX.Element = (
    <Box mx={2}>
      <Typography variant="subtitle2" component="div">
        {useMemo(
          () => (
            <Markdown remarkPlugins={[remarkGfm]}>{test.description || ''}</Markdown>
          ),
          [test.description],
        )}
      </Typography>
    </Box>
  );

  const a11yProps = (index: number) => ({
    id: `${test.id}-tab-${index}`,
    'aria-controls': `${test.id}-tabpanel-${index}`,
  });

  const renderTab = (tab: TabProps, index: number) => {
    const disableTab = (!tab.value || tab.value.length === 0) && tab.label !== 'About';

    return (
      <CustomTab
        key={`${tab.label}-${index}`}
        label={
          disableTab ? (
            <CustomTooltip title={`No ${tab.label.toLowerCase()} available`}>
              <Typography variant="button">{tab.label}</Typography>
            </CustomTooltip>
          ) : (
            tab.label
          )
        }
        {...a11yProps(index)}
        disabled={disableTab}
      />
    );
  };

  const showRequirementsClick = () => {
    const requirementIds = test.verifies_requirements;
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

  return (
    <Card data-testid="test-run-detail">
      <Tabs
        value={currentTabIndex}
        variant="scrollable"
        className={classes.tabs}
        onChange={(e, newIndex: number) => {
          setTabIndex(newIndex);
        }}
      >
        {tabs.map((tab, i) => renderTab(tab, i))}
      </Tabs>
      <Divider />
      <TabPanel id={test.id} currentTabIndex={currentTabIndex} index={0}>
        <MessageList messages={test.result?.messages || []} />
      </TabPanel>
      <TabPanel id={test.id} currentTabIndex={currentTabIndex} index={1}>
        {updateRequest && (
          <RequestList
            requests={test.result?.requests || []}
            resultId={test.result?.id || ''}
            updateRequest={updateRequest}
            view="run"
          />
        )}
      </TabPanel>
      <TabPanel id={test.id} currentTabIndex={currentTabIndex} index={2}>
        <InputOutputList
          inputOutputs={test.result?.inputs || []}
          noValuesMessage="No Inputs"
          headerName="Input"
        />
      </TabPanel>
      <TabPanel id={test.id} currentTabIndex={currentTabIndex} index={3}>
        <InputOutputList
          inputOutputs={test.result?.outputs || []}
          noValuesMessage="No Outputs"
          headerName="Output"
        />
      </TabPanel>
      <TabPanel id={test.id} currentTabIndex={currentTabIndex} index={4}>
        {shouldShowDescription(test, testDescription) ? (
          testDescription
        ) : (
          <Box p={2}>
            <Typography variant="subtitle2" component="p">
              No Description
            </Typography>
          </Box>
        )}
        {shouldShowRequirementsButton(test) && (
          <Box display="flex" justifyContent="end" minWidth="fit-content" px={2} pb={2}>
            <Link color="secondary" className={classes.textButton} onClick={showRequirementsClick}>
              View Specification Requirements
            </Link>
          </Box>
        )}
      </TabPanel>
      {requirements && shouldShowRequirementsButton(test) && (
        <RequirementsModal
          requirements={requirements}
          modalVisible={showRequirements}
          hideModal={() => setShowRequirements(false)}
        />
      )}
    </Card>
  );
};

export default TestRunDetail;
