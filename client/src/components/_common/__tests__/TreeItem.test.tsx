import React from 'react';
import { Router } from 'react-router';
import { createMemoryHistory } from 'history';
import { screen } from '@testing-library/react';
import { SimpleTreeView } from '@mui/x-tree-view/SimpleTreeView';
import TreeItemLabel from 'components/TestSuite/TestSuiteTree/TreeItemLabel';
import { renderWithProviders } from '~/test-utils';
import CustomTreeItem from '../CustomTreeItem';
import { mockedTestSuite } from '../__mocked_data__/mockData';
import { expect, test } from 'vitest';

test('renders custom TreeItem', () => {
  renderWithProviders(
    <SimpleTreeView>
      <CustomTreeItem
        itemId={mockedTestSuite.id}
        label={<TreeItemLabel runnable={mockedTestSuite} />}
        ContentProps={{ testId: mockedTestSuite.id } as any}
      />
    </SimpleTreeView>,
  );

  const treeItemElement = screen.getByRole('treeitem');
  expect(treeItemElement).toBeInTheDocument();
});

test('TreeItem expansion should not be toggled when label is clicked', async () => {
  const { user } = renderWithProviders(
    <SimpleTreeView expandedItems={[mockedTestSuite.id]}>
      <CustomTreeItem
        itemId={mockedTestSuite.id}
        label={<TreeItemLabel runnable={mockedTestSuite} />}
        ContentProps={{ testId: mockedTestSuite.id } as any}
      >
        <></>
      </CustomTreeItem>
    </SimpleTreeView>,
  );

  const labelElement = screen.getAllByTestId('tiLabel', { exact: false })[0];
  const treeItemElement = screen.getAllByRole('treeitem')[0];
  expect(labelElement).toBeInTheDocument();
  expect(treeItemElement).toHaveAttribute('aria-expanded', 'true');

  await user.click(labelElement);
  expect(treeItemElement).toHaveAttribute('aria-expanded', 'true');
});

test('clicking on TreeItem should navigate to group or test instance', async () => {
  const history = createMemoryHistory();
  history.push(`/${mockedTestSuite.id}/:test_session_id`);

  const { user } = renderWithProviders(
    <Router location={history.location} navigator={history}>
      <SimpleTreeView>
        <CustomTreeItem
          itemId={mockedTestSuite.id}
          label={<TreeItemLabel runnable={mockedTestSuite} />}
          ContentProps={{ testId: mockedTestSuite.id } as any}
        />
      </SimpleTreeView>
    </Router>,
    { noRouter: true },
  );

  const labelElement = screen.getAllByTestId('tiLabel', { exact: false })[0];
  expect(labelElement).toBeInTheDocument();

  await user.click(labelElement);
  expect(history.location.hash).toBe(`#${mockedTestSuite.id}`);
});
