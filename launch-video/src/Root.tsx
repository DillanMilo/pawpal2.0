import {Composition} from 'remotion';
import {PawPalLaunchVideo} from './PawPalLaunchVideo';

export const RemotionRoot = () => {
  return (
    <Composition
      id="PawPalLaunchVideo"
      component={PawPalLaunchVideo}
      durationInFrames={1260}
      fps={30}
      width={1080}
      height={1920}
    />
  );
};
