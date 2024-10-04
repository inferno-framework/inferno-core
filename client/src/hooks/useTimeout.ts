import { useEffect, useRef } from 'react';

type Timer = NodeJS.Timeout | undefined;

export const useTimeout = () => {
  const timeout = useRef<Timer>();
  useEffect(
    () => () => {
      if (timeout.current) {
        clearTimeout(timeout.current);
        timeout.current = undefined;
      }
    },
    [],
  );
  return timeout;
};
