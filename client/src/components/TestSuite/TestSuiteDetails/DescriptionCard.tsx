import React, { FC } from 'react';
import useStyles from './styles';
import { Card, Container, Divider } from '@material-ui/core';
import MardownDisplay from 'components/MarkdownDisplay/MarkdownDisplay';

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
        <MardownDisplay markdown={description} />
      </Container>
    </Card>
  );
};

export default DescriptionCard;
