import React, { FC, useEffect } from 'react';
import {
  TestInput,
  RunnableType,
  TestRun,
  Result,
  TestSession,
  TestGroup,
  Test,
  TestSuite,
  Request,
} from 'models/testSuiteModels';
import InputsModal from 'components/InputsModal/InputsModal';
import { getTestResults, postTestRun } from 'api/infernoApiService';
import useStyles from './styles';
import TestSuiteTreeComponent from './TestSuiteTree/TestSuiteTree';
import TestSuiteDetailsPanel from './TestSuiteDetails/TestSuiteDetailsPanel';
import { getAllContainedInputs } from './TestSuiteUtilities';
import { useLocation } from 'react-router-dom';

function mapRunnableRecursive(
  testGroup: TestGroup,
  map: Map<string, TestSuite | TestGroup | Test>
) {
  map.set(testGroup.id, testGroup);
  testGroup.test_groups.forEach((subGroup: TestGroup) => {
    mapRunnableRecursive(subGroup, map);
  });
  testGroup.tests.forEach((test: Test) => {
    map.set(test.id, test);
  });
}

function mapRunnableToId(testSuite: TestSuite): Map<string, TestSuite | TestGroup | Test> {
  const map = new Map<string, TestSuite | TestGroup | Test>();
  map.set(testSuite.id, testSuite);
  testSuite?.test_groups?.forEach((testGroup: TestGroup) => {
    mapRunnableRecursive(testGroup, map);
  });
  return map;
}

function resultsToMap(results: Result[], map?: Map<string, Result>): Map<string, Result> {
  let resultsMap: Map<string, Result>;
  if (map == undefined) {
    resultsMap = new Map<string, Result>();
  } else {
    resultsMap = map;
  }
  results.forEach((result: Result) => {
    if (result.test_suite_id) {
      resultsMap.set(result.test_suite_id, result);
    } else if (result.test_group_id) {
      resultsMap.set(result.test_group_id, result);
    } else if (result.test_id) {
      resultsMap.set(result.test_id, result);
    }
  });
  return new Map(resultsMap);
}

export interface TestSessionComponentProps {
  testSession: TestSession;
  previousResults: Result[];
}

const TestSessionComponent: FC<TestSessionComponentProps> = ({ testSession, previousResults }) => {
  const styles = useStyles();
  const { test_suite, id } = testSession;
  const [modalVisible, setModalVisible] = React.useState(false);
  const [inputs, setInputs] = React.useState<TestInput[]>([]);
  const [runnableType, setRunnableType] = React.useState<RunnableType>(RunnableType.TestSuite);
  const [runnableId, setRunnableId] = React.useState<string>('');
  const [resultsMap, setResultsMap] = React.useState<Map<string, Result>>(
    resultsToMap(previousResults)
  );
  const [sessionData, setSessionData] = React.useState<Map<string, string>>(new Map());

  useEffect(() => {
    const allInputs = getAllContainedInputs(test_suite.test_groups as TestGroup[]);
    allInputs.forEach((input: TestInput) => {
      const defaultValue = input.default ? input.default : '';
      sessionData.set(input.name, defaultValue);
    });
    setSessionData(new Map(sessionData));
  }, [testSession]);

  const runnableMap = React.useMemo(() => mapRunnableToId(test_suite), [test_suite]);
  const location = useLocation();
  let selectedRunnable = location.hash.replace('#', '');
  if (!runnableMap.get(selectedRunnable)) {
    selectedRunnable = testSession.test_suite.id;
  }

  function showInputsModal(runnableType: RunnableType, runnableId: string, inputs: TestInput[]) {
    setInputs(inputs);
    setRunnableType(runnableType);
    setRunnableId(runnableId);
    setModalVisible(true);
  }

  function saveTestRunResults(testRun: TestRun): void {
    getTestResults(testRun.id)
      .then((testRun_results: Result[]) => {
        const updatedMap = resultsToMap(testRun_results, resultsMap);
        setResultsMap(updatedMap);
      })
      .catch((e) => {
        console.log(e);
      });
  }

  function updateRequest(requestId: string, resultId: string, request: Request): void {
    const result = Array.from(resultsMap.values()).find((result) => result.id == resultId);
    if (result && result.requests) {
      const requestIndex = result.requests.findIndex((request) => request.id == requestId);
      result.requests[requestIndex] = request;
      setResultsMap(new Map(resultsMap));
    }
  }

  resultsMap.forEach((result, runnableId) => {
    const runnable = runnableMap.get(runnableId);
    if (runnable) {
      runnable.result = result;
    }
  });

  function runTests(runnableType: RunnableType, runnableId: string) {
    let allInputs: TestInput[] = [];
    if (runnableType == RunnableType.TestSuite) {
      const testSuite = runnableMap.get(runnableId) as TestSuite;
      if (testSuite && testSuite.test_groups) {
        allInputs = getAllContainedInputs(testSuite.test_groups);
      }
    } else if (runnableType == RunnableType.TestGroup) {
      const testGroup = runnableMap.get(runnableId) as TestGroup;
      if (testGroup) {
        allInputs = getAllContainedInputs([testGroup]);
      }
    } else {
      const test = runnableMap.get(runnableId) as Test;
      if (test) {
        allInputs = test.inputs;
      }
    }
    allInputs.forEach((input: TestInput) => {
      input.value = sessionData.get(input.name);
    });
    if (allInputs.length > 0) {
      showInputsModal(runnableType, runnableId, allInputs);
    } else {
      createTestRun(runnableType, runnableId, allInputs);
    }
  }

  function createTestRun(runnableType: RunnableType, runnableId: string, inputs: TestInput[]) {
    inputs.forEach((input: TestInput) => {
      sessionData.set(input.name, input.value as string);
    });
    setSessionData(new Map(sessionData));
    postTestRun(id, runnableType, runnableId, inputs)
      .then((testRun: TestRun) => {
        saveTestRunResults(testRun);
      })
      .catch((e) => {
        console.log(e);
      });
  }

  let detailsPanel: JSX.Element = <div>error</div>;
  if (runnableMap.get(selectedRunnable)) {
    detailsPanel = (
      <TestSuiteDetailsPanel
        runnable={runnableMap.get(selectedRunnable) as TestSuite | TestGroup}
        runTests={runTests}
        updateRequest={updateRequest}
      />
    );
  }
  return (
    <div className={styles.testSuiteMain}>
      <TestSuiteTreeComponent
        {...test_suite}
        runTests={runTests}
        selectedRunnable={selectedRunnable}
      />
      {detailsPanel}
      <InputsModal
        hideModal={() => setModalVisible(false)}
        createTestRun={createTestRun}
        modalVisible={modalVisible}
        runnableType={runnableType}
        runnableId={runnableId}
        inputs={inputs}
      />
    </div>
  );
};

export default TestSessionComponent;
