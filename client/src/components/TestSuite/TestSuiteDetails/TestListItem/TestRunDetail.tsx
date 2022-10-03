import React, { FC, useEffect, useMemo } from 'react';
import { Box, Card, Divider, ListItem, Tab, Tabs, Tooltip, Typography } from '@mui/material';
import { Message, Request, Test, TestInput, TestOutput } from '~/models/testSuiteModels';
import { shouldShowDescription } from '~/components/TestSuite/TestSuiteUtilities';
import TabPanel from '~/components/TestSuite/TestSuiteDetails/TestListItem/TabPanel';
import MessagesList from '~/components/TestSuite/TestSuiteDetails/TestListItem/MessagesList';
import RequestsList from '~/components/TestSuite/TestSuiteDetails/TestListItem/RequestsList';
import InputOutputsList from '~/components/TestSuite/TestSuiteDetails/TestListItem/InputOutputsList';
import lightTheme from '~/styles/theme';
import useStyles from './styles';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';

interface TestRunDetailProps {
  test: Test;
  currentTabIndex: number;
  updateRequest?: (requestId: string, resultId: string, request: Request) => void;
}

interface TabProps {
  label: string;
  value: Message[] | Request[] | TestInput[] | TestOutput[] | string | null | undefined;
}

const TestRunDetail: FC<TestRunDetailProps> = ({ test, currentTabIndex, updateRequest }) => {
  const styles = useStyles();
  const [tabIndex, setTabIndex] = React.useState(currentTabIndex);
  const tabs: TabProps[] = [
    { label: 'Messages', value: test.result?.messages },
    { label: 'Requests', value: test.result?.requests },
    { label: 'Inputs', value: test.result?.inputs },
    { label: 'Outputs', value: test.result?.outputs },
    { label: 'About', value: test.description },
  ];

  useEffect(() => {
    // Set active tab to first tab with data
    // If no tabs have data, set to About
    let tabIndex = 0;
    const disableableTabs = tabs.filter((tab) => tab.label !== 'About');
    for (let i = 0; i < disableableTabs.length; i++) {
      const content = disableableTabs[i].value;
      if (!content || content?.length === 0) tabIndex++;
      else break;
    }
    setTabIndex(tabIndex);
  }, [test.result]);

  const testDescription: JSX.Element = (
    <ListItem>
      <Typography variant="subtitle2" component="div">
        {useMemo(
          () => (
            <ReactMarkdown remarkPlugins={[remarkGfm]}>{test.description || ''}</ReactMarkdown>
          ),
          [test.description]
        )}
      </Typography>
    </ListItem>
  );

  const a11yProps = (index: number) => ({
    id: `${test.id}-tab-${index}`,
    'aria-controls': `${test.id}-tabpanel-${index}`,
  });

  const renderTab = (tab: TabProps, index: number) => {
    const darkTabText = {
      '&.Mui-selected': {
        color: lightTheme.palette.common.orangeDarker,
      },
    };

    if ((!tab.value || tab.value.length === 0) && tab.label !== 'About') {
      return (
        <Tab
          key={`${tab.label}-${index}`}
          label={
            <Tooltip title={`No ${tab.label.toLowerCase()} available`}>
              <Typography variant="button">{tab.label}</Typography>
            </Tooltip>
          }
          {...a11yProps(index)}
          disabled
          sx={darkTabText}
          style={{ pointerEvents: 'auto' }}
        />
      );
    }

    return (
      <Tab key={`${tab.label}-${index}`} label={tab.label} {...a11yProps(index)} sx={darkTabText} />
    );
  };

  return (
    <Card>
      <Tabs
        value={tabIndex}
        variant="scrollable"
        className={styles.tabs}
        onChange={(e, newIndex: number) => {
          setTabIndex(newIndex);
        }}
      >
        {tabs.map((tab, i) => renderTab(tab, i))}
      </Tabs>
      <Divider />
      <TabPanel id={test.id} currentTabIndex={tabIndex} index={0}>
        <MessagesList messages={test.result?.messages || []} />
      </TabPanel>
      <TabPanel id={test.id} currentTabIndex={tabIndex} index={1}>
        {updateRequest && (
          <RequestsList
            requests={test.result?.requests || []}
            resultId={test.result?.id || ''}
            updateRequest={updateRequest}
            view="run"
          />
        )}
      </TabPanel>
      <TabPanel id={test.id} currentTabIndex={tabIndex} index={2}>
        <InputOutputsList
          inputOutputs={test.result?.inputs || []}
          noValuesMessage="No Inputs"
          headerName="Input"
        />
      </TabPanel>
      <TabPanel id={test.id} currentTabIndex={tabIndex} index={3}>
        <InputOutputsList
          inputOutputs={test.result?.outputs || []}
          noValuesMessage="No Outputs"
          headerName="Output"
        />
      </TabPanel>
      <TabPanel id={test.id} currentTabIndex={tabIndex} index={4}>
        {shouldShowDescription(test, testDescription) ? (
          testDescription
        ) : (
          <Box p={2}>
            <Typography variant="subtitle2" component="p">
              No Description
            </Typography>
          </Box>
        )}
      </TabPanel>
    </Card>
  );
};

export default TestRunDetail;
