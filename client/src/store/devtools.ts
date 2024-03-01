import { devtools } from 'zustand/middleware';

// typing is tricky with devtools
// modified from https://github.com/pmndrs/zustand/discussions/842
/* eslint-disable @typescript-eslint/no-unsafe-return */
/* eslint-disable @typescript-eslint/no-explicit-any */
export const devtoolsInDev = (process.env.NODE_ENV === 'development'
  ? devtools
  : (fn: any) => fn) as unknown as typeof devtools;
