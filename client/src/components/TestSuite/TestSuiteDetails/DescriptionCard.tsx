import React, { FC } from 'react';
import useStyles from './styles';
import { Card, Container, Divider } from '@material-ui/core';
import ReactMarkdown from 'react-markdown';

interface DescriptionCardProps {
  description: string;
}

const DescriptionCard: FC<DescriptionCardProps> = ({ description }) => {
  const styles = useStyles();

  return (
    <Card variant="outlined">
      <div className={styles.descriptionCardHeader}>About</div>
      <Divider />
      <Container>
        <ReactMarkdown>{description}</ReactMarkdown>
      </Container>
    </Card>
  );
};

export default DescriptionCard;
