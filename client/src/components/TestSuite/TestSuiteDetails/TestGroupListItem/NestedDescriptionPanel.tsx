import React, { FC } from 'react';
import useStyles from './styles';
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
import ReactMarkdown from 'react-markdown';

interface NestedDescriptionPanelProps {
  testGroup: TestGroup;
}

const NestedDescriptionPanel: FC<NestedDescriptionPanelProps> = ({ testGroup }) => {
  const { classes } = useStyles();
  const [descriptionMouseHover, setDescriptionMouseHover] = React.useState(false);

  return (
    <Box className={classes.nestedDescriptionContainer}>
      <Accordion
        disableGutters
        key={`${testGroup.id}-description`}
        className={classes.accordion}
        TransitionProps={{ unmountOnExit: true }}
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
                  <Typography className={classes.nestedDescriptionHeader}>
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
          className={classes.accordionDetailContainer}
        >
          <ReactMarkdown className={`${classes.accordionDetail} ${classes.nestedDescription}`}>
            {testGroup.description as string}
          </ReactMarkdown>
        </AccordionDetails>
      </Accordion>
    </Box>
  );
};

export default NestedDescriptionPanel;
