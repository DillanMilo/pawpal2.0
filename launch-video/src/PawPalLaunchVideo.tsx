import React from 'react';
import {
  AbsoluteFill,
  Easing,
  Img,
  interpolate,
  spring,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
} from 'remotion';

const colors = {
  ink: '#161923',
  muted: '#4f5968',
  soft: '#f4f6fb',
  card: '#ffffff',
  line: '#dde3ee',
  purple: '#6554d9',
  purpleLight: '#8f82f2',
  teal: '#0e9f9a',
  tealLight: '#5ccbc7',
  gold: '#e9b949',
  peach: '#e98b6d',
  mint: '#68c7a0',
  rose: '#e56b93',
  red: '#ff5252',
};

const scenes = [
  {start: 0, end: 150, eyebrow: 'Meet PawPal', title: 'Everything your pet needs, in one calm place.', tag: 'Profiles, care, activity, reminders, records'},
  {start: 150, end: 330, eyebrow: 'Pet profiles', title: 'Add every pet. Keep every detail close.', tag: 'Photos, breed, weight, microchip, birthday'},
  {start: 330, end: 510, eyebrow: 'Health stats', title: 'Track care history before it becomes guesswork.', tag: 'Vaccines, meds, allergies, vet visits'},
  {start: 510, end: 690, eyebrow: 'Daily activity', title: 'Log walks, play, training, feeding, and rest.', tag: 'Points, streaks, weekly charts'},
  {start: 690, end: 870, eyebrow: 'Reminders & calendar', title: 'Never miss the next dose, grooming, or appointment.', tag: 'Recurring reminders and marked dates'},
  {start: 870, end: 1050, eyebrow: 'Passport & services', title: 'Share health info and find trusted local providers.', tag: 'Privacy toggles, QR passport, vets and groomers'},
  {start: 1050, end: 1260, eyebrow: 'Launch care mode', title: 'PawPal keeps the whole pack organized.', tag: 'Built for modern pet parents'},
];

const pets = [
  {name: 'Milo', type: 'Dog', stat: '42 lb', color: colors.purple},
  {name: 'Luna', type: 'Cat', stat: '9 lb', color: colors.rose},
  {name: 'Kiwi', type: 'Bird', stat: '2 yr', color: colors.gold},
];

const records = [
  {label: 'Rabies vaccine', value: 'Due Jun 14', color: colors.teal},
  {label: 'Allergy', value: 'Chicken', color: colors.rose},
  {label: 'Medication', value: '2x daily', color: colors.purple},
];

const activities = [
  {label: 'Walk', value: 88, color: colors.teal},
  {label: 'Play', value: 72, color: colors.gold},
  {label: 'Train', value: 54, color: colors.purple},
  {label: 'Feed', value: 42, color: colors.mint},
  {label: 'Rest', value: 60, color: colors.peach},
];

const reminders = [
  {title: 'Heartworm dose', time: 'Today 6:00 PM', color: colors.purple},
  {title: 'Grooming', time: 'Fri 11:30 AM', color: colors.peach},
  {title: 'Wellness exam', time: 'May 18', color: colors.teal},
];

const providers = [
  {name: 'Oak Grove Vet', meta: '4.8 open now', color: colors.teal},
  {name: 'Fresh Coat Grooming', meta: '1.2 mi away', color: colors.peach},
];

const ease = Easing.bezier(0.16, 1, 0.3, 1);

const clamp = {
  extrapolateLeft: 'clamp' as const,
  extrapolateRight: 'clamp' as const,
};

const useSceneProgress = (start: number, end: number) => {
  const frame = useCurrentFrame();
  return interpolate(frame, [start, start + 30, end - 28, end], [0, 1, 1, 0], {
    ...clamp,
    easing: ease,
  });
};

const SceneText: React.FC = () => {
  const frame = useCurrentFrame();
  const scene = scenes.find((item) => frame >= item.start && frame < item.end) ?? scenes[0];
  const progress = useSceneProgress(scene.start, scene.end);
  const y = interpolate(progress, [0, 1], [34, 0], clamp);

  return (
    <div
      style={{
        position: 'absolute',
        left: 80,
        right: 80,
        top: 112,
        opacity: progress,
        transform: `translateY(${y}px)`,
      }}
    >
      <div
        style={{
          display: 'inline-flex',
          alignItems: 'center',
          gap: 14,
          borderRadius: 999,
          padding: '14px 22px',
          background: 'rgba(255,255,255,0.78)',
          color: colors.purple,
          fontSize: 28,
          fontWeight: 800,
          boxShadow: '0 16px 40px rgba(16,24,40,0.08)',
        }}
      >
        <Img src={staticFile('pawpal-mark.svg')} style={{width: 32, height: 32}} />
        {scene.eyebrow}
      </div>
      <h1
        style={{
          margin: '34px 0 24px',
          color: colors.ink,
          fontSize: 72,
          lineHeight: 0.98,
          letterSpacing: 0,
          fontWeight: 900,
          maxWidth: 900,
        }}
      >
        {scene.title}
      </h1>
      <p
        style={{
          margin: 0,
          color: colors.muted,
          fontSize: 34,
          lineHeight: 1.22,
          fontWeight: 600,
          maxWidth: 820,
        }}
      >
        {scene.tag}
      </p>
    </div>
  );
};

const PhoneFrame: React.FC<{children: React.ReactNode; x?: number; y?: number; scale?: number}> = ({
  children,
  x = 0,
  y = 0,
  scale = 1,
}) => {
  const frame = useCurrentFrame();
  const pop = spring({frame, fps: 30, config: {damping: 16, stiffness: 90}});

  return (
    <div
      style={{
        position: 'absolute',
        width: 650,
        height: 1260,
        left: 215 + x,
        top: 430 + y,
        borderRadius: 74,
        background: '#101828',
        padding: 18,
        boxShadow: '0 46px 110px rgba(34, 37, 60, 0.28)',
        transform: `scale(${scale * interpolate(pop, [0, 1], [0.94, 1], clamp)})`,
      }}
    >
      <div
        style={{
          width: '100%',
          height: '100%',
          overflow: 'hidden',
          borderRadius: 58,
          background: colors.soft,
          position: 'relative',
          border: '1px solid rgba(255,255,255,0.22)',
        }}
      >
        <div
          style={{
            position: 'absolute',
            top: 16,
            left: '50%',
            width: 168,
            height: 34,
            transform: 'translateX(-50%)',
            borderRadius: 999,
            background: '#101828',
            zIndex: 5,
          }}
        />
        {children}
      </div>
    </div>
  );
};

const AppHeader: React.FC<{title: string; subtitle?: string}> = ({title, subtitle}) => (
  <div style={{padding: '76px 34px 18px'}}>
    <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center'}}>
      <div>
        <div style={{fontSize: 25, color: colors.muted, fontWeight: 700}}>{subtitle ?? 'Good morning'}</div>
        <div style={{fontSize: 43, color: colors.ink, fontWeight: 900, marginTop: 6}}>{title}</div>
      </div>
      <div
        style={{
          width: 64,
          height: 64,
          borderRadius: 20,
          background: `linear-gradient(135deg, ${colors.purple}, ${colors.teal})`,
          display: 'grid',
          placeItems: 'center',
        }}
      >
        <Img src={staticFile('pawpal-mark.svg')} style={{width: 36, height: 36, filter: 'brightness(0) invert(1)'}} />
      </div>
    </div>
  </div>
);

const PetAvatar: React.FC<{name: string; type: string; color: string; size?: number}> = ({name, type, color, size = 118}) => (
  <div
    style={{
      width: size,
      height: size,
      borderRadius: size * 0.3,
      background: `linear-gradient(135deg, ${color}, ${colors.tealLight})`,
      display: 'grid',
      placeItems: 'center',
      color: '#fff',
      fontSize: size * 0.34,
      fontWeight: 900,
      boxShadow: `0 18px 34px ${color}44`,
      position: 'relative',
      overflow: 'hidden',
    }}
  >
    <div style={{position: 'absolute', right: -18, bottom: -18, width: size * 0.72, height: size * 0.72, borderRadius: 999, background: 'rgba(255,255,255,0.2)'}} />
    <span style={{zIndex: 1}}>{name.slice(0, 1)}</span>
    <span style={{position: 'absolute', bottom: 15, fontSize: size * 0.12, fontWeight: 800, opacity: 0.9}}>{type}</span>
  </div>
);

const HomeScreen: React.FC = () => {
  const frame = useCurrentFrame();
  const p = useSceneProgress(0, 150);
  const bars = [58, 78, 44, 92, 68, 84, 52];

  return (
    <>
      <AppHeader title="PawPal" subtitle="Care dashboard" />
      <div style={{padding: '0 34px'}}>
        <div
          style={{
            borderRadius: 34,
            padding: 26,
            minHeight: 260,
            background: `linear-gradient(135deg, ${colors.purple}, ${colors.teal})`,
            color: '#fff',
            boxShadow: '0 24px 48px rgba(101,84,217,0.25)',
          }}
        >
          <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center'}}>
            <div>
              <div style={{fontSize: 28, fontWeight: 800, opacity: 0.82}}>Today with Milo</div>
              <div style={{fontSize: 58, fontWeight: 900, marginTop: 20}}>3 tasks left</div>
            </div>
            <PetAvatar name="Milo" type="Dog" color={colors.purpleLight} />
          </div>
          <div style={{display: 'flex', gap: 12, marginTop: 34}}>
            {['Walk', 'Medication', 'Vet'].map((item, index) => (
              <div key={item} style={{padding: '14px 18px', borderRadius: 999, background: 'rgba(255,255,255,0.18)', fontSize: 23, fontWeight: 800}}>
                {item}
              </div>
            ))}
          </div>
        </div>
        <div style={{display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 16, marginTop: 20}}>
          {[
            ['1,280', 'Paw Points', colors.gold],
            ['12', 'Day Streak', colors.teal],
            ['3', 'Pets', colors.rose],
          ].map(([value, label, color]) => (
            <div key={label} style={{borderRadius: 28, background: '#fff', padding: 22, boxShadow: '0 12px 28px rgba(16,24,40,0.07)'}}>
              <div style={{fontSize: 35, fontWeight: 900, color}}>{value}</div>
              <div style={{fontSize: 19, fontWeight: 700, color: colors.muted, marginTop: 6}}>{label}</div>
            </div>
          ))}
        </div>
        <div style={{borderRadius: 30, background: '#fff', marginTop: 20, padding: 24}}>
          <div style={{fontSize: 27, color: colors.ink, fontWeight: 900}}>Weekly activity</div>
          <div style={{display: 'flex', alignItems: 'end', gap: 14, height: 190, marginTop: 20}}>
            {bars.map((height, index) => {
              const grow = interpolate(frame, [18 + index * 4, 48 + index * 4], [0.18, 1], clamp);
              return <div key={index} style={{width: 54, height: height * 1.65 * grow, borderRadius: 16, background: index === 3 ? colors.purple : colors.tealLight}} />;
            })}
          </div>
        </div>
      </div>
      <FloatingChips progress={p} />
    </>
  );
};

const FloatingChips: React.FC<{progress: number}> = ({progress}) => {
  const chips = [
    {text: 'Vaccines current', top: 1030, left: -74, color: colors.teal},
    {text: '+20 vet points', top: 1180, left: 500, color: colors.gold},
    {text: 'QR passport ready', top: 1360, left: -34, color: colors.purple},
  ];

  return (
    <>
      {chips.map((chip, index) => (
        <div
          key={chip.text}
          style={{
            position: 'absolute',
            top: chip.top,
            left: chip.left,
            opacity: progress,
            transform: `translateY(${Math.sin(progress * Math.PI + index) * 16}px)`,
            borderRadius: 999,
            padding: '18px 24px',
            background: '#fff',
            color: chip.color,
            fontSize: 25,
            fontWeight: 900,
            boxShadow: '0 18px 42px rgba(16,24,40,0.12)',
          }}
        >
          {chip.text}
        </div>
      ))}
    </>
  );
};

const PetProfilesScreen: React.FC = () => {
  const frame = useCurrentFrame();
  return (
    <>
      <AppHeader title="My Pets" subtitle="Unlimited profiles" />
      <div style={{padding: '0 34px'}}>
        {pets.map((pet, index) => {
          const enter = interpolate(frame, [150 + index * 14, 190 + index * 14], [54, 0], clamp);
          return (
            <div
              key={pet.name}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: 22,
                marginBottom: 18,
                padding: 24,
                borderRadius: 32,
                background: '#fff',
                transform: `translateX(${enter}px)`,
                boxShadow: '0 13px 30px rgba(16,24,40,0.07)',
              }}
            >
              <PetAvatar name={pet.name} type={pet.type} color={pet.color} size={104} />
              <div style={{flex: 1}}>
                <div style={{fontSize: 34, fontWeight: 900, color: colors.ink}}>{pet.name}</div>
                <div style={{fontSize: 23, fontWeight: 700, color: colors.muted, marginTop: 4}}>{pet.type} profile</div>
              </div>
              <div style={{fontSize: 30, fontWeight: 900, color: pet.color}}>{pet.stat}</div>
            </div>
          );
        })}
        <div style={{borderRadius: 34, background: `linear-gradient(135deg, ${colors.purple}, ${colors.purpleLight})`, padding: 28, color: '#fff', marginTop: 12}}>
          <div style={{fontSize: 28, fontWeight: 800, opacity: 0.85}}>Add pet details</div>
          <div style={{display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 14, marginTop: 20}}>
            {['Photo', 'Breed', 'DOB', 'Microchip', 'Weight', 'Color'].map((item) => (
              <div key={item} style={{borderRadius: 18, background: 'rgba(255,255,255,0.16)', padding: '15px 18px', fontSize: 22, fontWeight: 800}}>
                {item}
              </div>
            ))}
          </div>
        </div>
      </div>
    </>
  );
};

const HealthScreen: React.FC = () => {
  const frame = useCurrentFrame();
  return (
    <>
      <AppHeader title="Milo Health" subtitle="Medical records" />
      <div style={{padding: '0 34px'}}>
        <div style={{borderRadius: 34, background: '#fff', padding: 28, boxShadow: '0 14px 32px rgba(16,24,40,0.07)'}}>
          <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center'}}>
            <div>
              <div style={{fontSize: 26, color: colors.muted, fontWeight: 800}}>Care status</div>
              <div style={{fontSize: 48, color: colors.ink, fontWeight: 900, marginTop: 5}}>Healthy</div>
            </div>
            <div style={{width: 126, height: 126, borderRadius: 999, background: `${colors.teal}22`, display: 'grid', placeItems: 'center', color: colors.teal, fontSize: 44, fontWeight: 900}}>
              98
            </div>
          </div>
          <div style={{height: 14, background: colors.line, borderRadius: 999, marginTop: 26, overflow: 'hidden'}}>
            <div style={{height: '100%', width: `${interpolate(frame, [350, 410], [12, 88], clamp)}%`, background: colors.teal, borderRadius: 999}} />
          </div>
        </div>
        <div style={{marginTop: 22}}>
          {records.map((record, index) => (
            <div key={record.label} style={{display: 'flex', alignItems: 'center', gap: 18, borderRadius: 28, background: '#fff', padding: 22, marginBottom: 16}}>
              <div style={{width: 58, height: 58, borderRadius: 18, background: `${record.color}22`, color: record.color, display: 'grid', placeItems: 'center', fontSize: 27, fontWeight: 900}}>
                {index + 1}
              </div>
              <div style={{flex: 1}}>
                <div style={{fontSize: 27, fontWeight: 900, color: colors.ink}}>{record.label}</div>
                <div style={{fontSize: 22, fontWeight: 700, color: colors.muted, marginTop: 4}}>{record.value}</div>
              </div>
            </div>
          ))}
        </div>
        <div style={{borderRadius: 30, padding: 24, background: colors.ink, color: '#fff', marginTop: 10}}>
          <div style={{fontSize: 31, fontWeight: 900}}>Attachments included</div>
          <div style={{fontSize: 22, fontWeight: 700, opacity: 0.75, marginTop: 10}}>Photos and documents stay with each record.</div>
        </div>
      </div>
    </>
  );
};

const ActivityScreen: React.FC = () => {
  const frame = useCurrentFrame();
  return (
    <>
      <AppHeader title="Log Activity" subtitle="Earn Paw Points" />
      <div style={{padding: '0 34px'}}>
        <div style={{display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16}}>
          {activities.map((activity, index) => {
            const scale = interpolate(frame, [520 + index * 7, 550 + index * 7], [0.86, 1], clamp);
            return (
              <div key={activity.label} style={{borderRadius: 30, background: '#fff', padding: 24, transform: `scale(${scale})`, transformOrigin: 'center', boxShadow: '0 13px 30px rgba(16,24,40,0.07)'}}>
                <div style={{width: 58, height: 58, borderRadius: 18, background: `${activity.color}24`, color: activity.color, display: 'grid', placeItems: 'center', fontSize: 27, fontWeight: 900}}>
                  {activity.label.slice(0, 1)}
                </div>
                <div style={{fontSize: 28, color: colors.ink, fontWeight: 900, marginTop: 22}}>{activity.label}</div>
                <div style={{fontSize: 21, color: colors.muted, fontWeight: 700, marginTop: 4}}>+ points</div>
              </div>
            );
          })}
        </div>
        <div style={{borderRadius: 34, background: '#fff', padding: 26, marginTop: 22}}>
          <div style={{fontSize: 28, fontWeight: 900, color: colors.ink}}>Week at a glance</div>
          <div style={{display: 'flex', alignItems: 'end', gap: 15, height: 210, marginTop: 20}}>
            {activities.map((activity, index) => {
              const grow = interpolate(frame, [575 + index * 9, 630 + index * 9], [0.08, 1], clamp);
              return <div key={activity.label} style={{width: 82, height: activity.value * 2.1 * grow, borderRadius: 20, background: activity.color}} />;
            })}
          </div>
        </div>
        <div style={{display: 'flex', gap: 16, marginTop: 20}}>
          <Metric value="12" label="Day streak" color={colors.purple} />
          <Metric value="86" label="Today pts" color={colors.gold} />
        </div>
      </div>
    </>
  );
};

const Metric: React.FC<{value: string; label: string; color: string}> = ({value, label, color}) => (
  <div style={{flex: 1, borderRadius: 28, background: '#fff', padding: 24}}>
    <div style={{fontSize: 43, color, fontWeight: 900}}>{value}</div>
    <div style={{fontSize: 21, color: colors.muted, fontWeight: 800}}>{label}</div>
  </div>
);

const ReminderScreen: React.FC = () => {
  const frame = useCurrentFrame();
  const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  return (
    <>
      <AppHeader title="Care Calendar" subtitle="Reminders" />
      <div style={{padding: '0 34px'}}>
        <div style={{borderRadius: 34, background: '#fff', padding: 24}}>
          <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center'}}>
            <div style={{fontSize: 31, color: colors.ink, fontWeight: 900}}>May</div>
            <div style={{fontSize: 22, color: colors.purple, fontWeight: 900}}>3 due soon</div>
          </div>
          <div style={{display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', gap: 12, marginTop: 22}}>
            {days.map((day, index) => (
              <div key={`${day}-${index}`} style={{textAlign: 'center', color: colors.muted, fontSize: 18, fontWeight: 900}}>{day}</div>
            ))}
            {Array.from({length: 28}).map((_, index) => {
              const marked = [4, 12, 17, 22].includes(index);
              const active = index === 12;
              return (
                <div key={index} style={{height: 54, borderRadius: 16, display: 'grid', placeItems: 'center', background: active ? colors.purple : marked ? `${colors.teal}22` : colors.soft, color: active ? '#fff' : colors.ink, fontSize: 19, fontWeight: 900}}>
                  {index + 1}
                </div>
              );
            })}
          </div>
        </div>
        <div style={{marginTop: 22}}>
          {reminders.map((reminder, index) => {
            const x = interpolate(frame, [710 + index * 10, 748 + index * 10], [60, 0], clamp);
            return (
              <div key={reminder.title} style={{display: 'flex', gap: 18, alignItems: 'center', borderRadius: 28, background: '#fff', padding: 22, marginBottom: 16, transform: `translateX(${x}px)`}}>
                <div style={{width: 62, height: 62, borderRadius: 20, background: `${reminder.color}22`, color: reminder.color, display: 'grid', placeItems: 'center', fontSize: 24, fontWeight: 900}}>!</div>
                <div style={{flex: 1}}>
                  <div style={{fontSize: 27, fontWeight: 900, color: colors.ink}}>{reminder.title}</div>
                  <div style={{fontSize: 21, fontWeight: 700, color: colors.muted, marginTop: 4}}>{reminder.time}</div>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </>
  );
};

const PassportServicesScreen: React.FC = () => {
  const frame = useCurrentFrame();
  const scan = interpolate(frame, [895, 1010], [0, 1], clamp);
  return (
    <>
      <AppHeader title="Passport" subtitle="Share safely" />
      <div style={{padding: '0 34px'}}>
        <div style={{borderRadius: 36, background: colors.ink, color: '#fff', padding: 28, boxShadow: '0 20px 42px rgba(16,24,40,0.16)'}}>
          <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center'}}>
            <div>
              <div style={{fontSize: 24, fontWeight: 800, opacity: 0.72}}>Milo's QR passport</div>
              <div style={{fontSize: 40, fontWeight: 900, marginTop: 8}}>Ready to share</div>
            </div>
            <div style={{width: 160, height: 160, borderRadius: 24, background: '#fff', padding: 18, position: 'relative'}}>
              <QrPattern />
              <div style={{position: 'absolute', left: 18, right: 18, top: 18 + scan * 112, height: 5, background: colors.teal, boxShadow: `0 0 18px ${colors.teal}`}} />
            </div>
          </div>
          <div style={{display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 14, marginTop: 24}}>
            {['Basics', 'Vaccines', 'Meds', 'Allergies'].map((item) => (
              <div key={item} style={{borderRadius: 18, padding: '14px 16px', background: 'rgba(255,255,255,0.12)', fontSize: 20, fontWeight: 900}}>
                {item}
              </div>
            ))}
          </div>
        </div>
        <div style={{fontSize: 30, fontWeight: 900, color: colors.ink, margin: '28px 0 16px'}}>Nearby care</div>
        {providers.map((provider) => (
          <div key={provider.name} style={{display: 'flex', alignItems: 'center', gap: 18, borderRadius: 28, background: '#fff', padding: 22, marginBottom: 16}}>
            <div style={{width: 66, height: 66, borderRadius: 20, background: `${provider.color}24`, color: provider.color, display: 'grid', placeItems: 'center', fontSize: 25, fontWeight: 900}}>{provider.name.slice(0, 1)}</div>
            <div style={{flex: 1}}>
              <div style={{fontSize: 27, color: colors.ink, fontWeight: 900}}>{provider.name}</div>
              <div style={{fontSize: 21, color: colors.muted, fontWeight: 700, marginTop: 4}}>{provider.meta}</div>
            </div>
            <div style={{fontSize: 22, color: colors.purple, fontWeight: 900}}>Call</div>
          </div>
        ))}
      </div>
    </>
  );
};

const QrPattern: React.FC = () => (
  <div style={{display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', gap: 5}}>
    {Array.from({length: 49}).map((_, index) => {
      const filled = [0, 1, 2, 4, 5, 6, 7, 9, 13, 14, 15, 16, 18, 20, 24, 26, 28, 30, 31, 34, 35, 36, 38, 40, 42, 43, 44, 46, 48].includes(index);
      return <div key={index} style={{height: 13, borderRadius: 3, background: filled ? colors.ink : '#edf1f7'}} />;
    })}
  </div>
);

const FinalScreen: React.FC = () => {
  const frame = useCurrentFrame();
  const progress = useSceneProgress(1050, 1260);
  const scale = interpolate(progress, [0, 1], [0.9, 1], clamp);
  const glow = interpolate(frame, [1110, 1230], [0, 1], clamp);

  return (
    <div style={{position: 'absolute', inset: 0, display: 'grid', placeItems: 'center', opacity: progress, transform: `scale(${scale})`}}>
      <div style={{textAlign: 'center', padding: '0 80px'}}>
        <div style={{display: 'inline-grid', placeItems: 'center', width: 190, height: 190, borderRadius: 54, background: `linear-gradient(135deg, ${colors.purple}, ${colors.teal})`, boxShadow: `0 0 ${50 + glow * 80}px rgba(101,84,217,0.36)`}}>
          <Img src={staticFile('pawpal-mark.svg')} style={{width: 102, height: 102, filter: 'brightness(0) invert(1)'}} />
        </div>
        <div style={{marginTop: 42, display: 'flex', justifyContent: 'center'}}>
          <Img src={staticFile('pawpal-logo.svg')} style={{width: 420, height: 'auto'}} />
        </div>
        <h2 style={{fontSize: 72, lineHeight: 1, color: colors.ink, fontWeight: 950, margin: '44px 0 22px', letterSpacing: 0}}>
          Smarter pet care starts here.
        </h2>
        <p style={{fontSize: 34, lineHeight: 1.24, fontWeight: 700, color: colors.muted, margin: 0}}>
          Track pets, health, activities, reminders, passports, and providers in one app.
        </p>
      </div>
    </div>
  );
};

const ScreenSwitcher: React.FC = () => {
  const frame = useCurrentFrame();

  if (frame >= 1050) {
    return null;
  }

  const active =
    frame < 150 ? <HomeScreen /> :
    frame < 330 ? <PetProfilesScreen /> :
    frame < 510 ? <HealthScreen /> :
    frame < 690 ? <ActivityScreen /> :
    frame < 870 ? <ReminderScreen /> :
    <PassportServicesScreen />;

  return active;
};

export const PawPalLaunchVideo: React.FC = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const bgShift = interpolate(frame, [0, 1260], [0, 1], clamp);
  const phoneTilt = interpolate(Math.sin((frame / fps) * 0.7), [-1, 1], [-1.7, 1.7]);
  const phoneExit = interpolate(frame, [1020, 1070], [1, 0], clamp);

  return (
    <AbsoluteFill style={{background: colors.soft, overflow: 'hidden', fontFamily: 'Arial, Helvetica, sans-serif'}}>
      <div
        style={{
          position: 'absolute',
          inset: -220,
          background: `radial-gradient(circle at ${20 + bgShift * 35}% 18%, rgba(101,84,217,0.18), transparent 34%), radial-gradient(circle at 82% ${72 - bgShift * 38}%, rgba(14,159,154,0.18), transparent 30%), linear-gradient(180deg, #fff 0%, #f4f6fb 58%, #eef7f5 100%)`,
        }}
      />
      <SceneText />
      <div style={{opacity: phoneExit, transform: `rotate(${phoneTilt}deg)`}}>
        <PhoneFrame>
          <ScreenSwitcher />
        </PhoneFrame>
      </div>
      <FinalScreen />
      <div style={{position: 'absolute', left: 80, right: 80, bottom: 58, display: 'flex', justifyContent: 'space-between', alignItems: 'center', opacity: interpolate(frame, [40, 80, 1180, 1240], [0, 1, 1, 0], clamp)}}>
        <div style={{display: 'flex', alignItems: 'center', gap: 14, color: colors.muted, fontSize: 24, fontWeight: 800}}>
          <Img src={staticFile('pawpal-mark.svg')} style={{width: 34, height: 34}} />
          PawPal
        </div>
        <div style={{width: 320, height: 8, borderRadius: 999, background: colors.line, overflow: 'hidden'}}>
          <div style={{height: '100%', width: `${interpolate(frame, [0, 1260], [0, 100], clamp)}%`, background: `linear-gradient(90deg, ${colors.purple}, ${colors.teal})`}} />
        </div>
      </div>
    </AbsoluteFill>
  );
};
