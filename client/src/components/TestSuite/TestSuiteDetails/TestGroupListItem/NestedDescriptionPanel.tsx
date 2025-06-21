import React, { FC } from 'react';
import Markdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import {
  Accordion,
  AccordionDetails,
  AccordionSummary,
  Box,
  Divider,
  List,
  ListItem,
  ListItemText,
  Typography,
} from '@mui/material';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import { TestGroup } from '~/models/testSuiteModels';
import useStyles from './styles';
import { shouldShowRequirementsButton } from '~/components/TestSuite/TestSuiteUtilities';
import RequirementsModalButton from '~/components/TestSuite/Requirements/RequirementsModalButton';

interface NestedDescriptionPanelProps {
  testGroup: TestGroup;
}

const NestedDescriptionPanel: FC<NestedDescriptionPanelProps> = ({ testGroup }) => {
  const { classes } = useStyles();
  const [descriptionMouseHover, setDescriptionMouseHover] = React.useState(false);
  const showRequirementsButton = shouldShowRequirementsButton(testGroup);

  return (
    <Box py={1} className={classes.descriptionContainer}>
      <Accordion
        disableGutters
        elevation={0}
        key={`${testGroup.id}-description`}
        className={classes.accordion}
        slotProps={{ transition: { unmountOnExit: true } }}
        onMouseEnter={() => setDescriptionMouseHover(true)}
        onMouseLeave={() => setDescriptionMouseHover(false)}
      >
        <AccordionSummary
          id={descriptionMouseHover ? '' : `${testGroup.id}-description-summary`}
          aria-controls={`${testGroup.id}-description-detail`}
          expandIcon={<ExpandMoreIcon sx={{ padding: '0 5px' }} />}
          sx={{ userSelect: 'auto' }}
        >
          <List sx={{ p: 0 }}>
            <ListItem sx={{ p: 0 }}>
              <ListItemText
                primary={
                  <Typography className={classes.descriptionHeader}>
                    About {testGroup.short_title || testGroup.title}
                  </Typography>
                }
              />
            </ListItem>
          </List>
        </AccordionSummary>
        <Divider />
        <AccordionDetails
          title={descriptionMouseHover ? '' : `${testGroup.id}-description-detail`}
          className={classes.descriptionDetailContainer}
        >
          <Box className={`${classes.accordionDetail} ${classes.description}`}>
            <Markdown remarkPlugins={[remarkGfm]}>{testGroup.description as string}</Markdown>
            {showRequirementsButton && <RequirementsModalButton runnable={testGroup} />}
          </Box>
        </AccordionDetails>
      </Accordion>
    </Box>
  );
};

export default NestedDescriptionPanel;
