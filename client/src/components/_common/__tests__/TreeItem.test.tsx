import React from 'react';
import { Router, BrowserRouter } from 'react-router-dom';
import { createMemoryHistory } from 'history';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { TreeView } from '@mui/x-tree-view/TreeView';
import TreeItemLabel from 'components/TestSuite/TestSuiteTree/TreeItemLabel';
import ThemeProvider from 'components/ThemeProvider';
import CustomTreeItem from '../CustomTreeItem';
import { mockedTestSuite } from '../__mocked_data__/mockData';

test('renders custom TreeItem', () => {
  render(
    <BrowserRouter>
      <ThemeProvider>
        <TreeView>
          <CustomTreeItem
            nodeId={mockedTestSuite.id}
            label={<TreeItemLabel runnable={mockedTestSuite} />}
            ContentProps={{ testId: mockedTestSuite.id } as any}
          />
        </TreeView>
      </ThemeProvider>
    </BrowserRouter>
  );

  const treeItemElement = screen.getByRole('treeitem');
  expect(treeItemElement).toBeInTheDocument();
});

test('TreeItem expansion should not be toggled when label is clicked', () => {
  render(
    <BrowserRouter>
      <ThemeProvider>
        <TreeView expanded={[mockedTestSuite.id]}>
          <CustomTreeItem
            nodeId={mockedTestSuite.id}
            label={<TreeItemLabel runnable={mockedTestSuite} />}
            ContentProps={{ testId: mockedTestSuite.id } as any}
          >
            <></>
          </CustomTreeItem>
        </TreeView>
      </ThemeProvider>
    </BrowserRouter>
  );

  const labelElement = screen.getAllByTestId('tiLabel', { exact: false })[0];
  const treeItemElement = screen.getAllByRole('treeitem')[0];
  expect(labelElement).toBeInTheDocument();
  expect(treeItemElement).toHaveAttribute('aria-expanded', 'true');

  userEvent.click(labelElement);
  expect(treeItemElement).toHaveAttribute('aria-expanded', 'true');
});

test('clicking on TreeItem should navigate to group or test instance', () => {
  const history = createMemoryHistory();
  history.push(`/${mockedTestSuite.id}/:test_session_id`);

  render(
    <Router location={history.location} navigator={history}>
      <ThemeProvider>
        <TreeView>
          <CustomTreeItem
            nodeId={mockedTestSuite.id}
            label={<TreeItemLabel runnable={mockedTestSuite} />}
            ContentProps={{ testId: mockedTestSuite.id } as any}
          />
        </TreeView>
      </ThemeProvider>
    </Router>
  );

  const labelElement = screen.getAllByTestId('tiLabel', { exact: false })[0];
  expect(labelElement).toBeInTheDocument();

  userEvent.click(labelElement);
  expect(history.location.hash).toBe(`#${mockedTestSuite.id}`);
});
