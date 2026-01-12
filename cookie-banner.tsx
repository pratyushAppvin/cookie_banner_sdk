import axios from 'axios';
import Cookies from 'js-cookie';
import React, { Suspense, useEffect, useRef, useState } from 'react';
import {
  browserName,
  browserVersion,
  deviceType,
  isDesktop,
  isMobile,
  isTablet,
  mobileModel,
  mobileVendor,
  osName,
  osVersion,
} from 'react-device-detect';
import { useMediaQuery } from 'react-responsive';
import {
  Accordion,
  AccordionContent,
  AccordionItem,
  AccordionTrigger,
} from '../../@/components/ui/basic-accordion';
import BasicSwitch from '../../@/components/ui/basic-switch';
import gotrustTitle from '../../assets/gotrustTitle_light.svg';
import { getFontFamilyWithFallbacks, loadGoogleFont } from '../../utils/fontLoader';
import { convertDateToHumanView, convertString } from '../common/CommonHelperFunctions';
import {
  BannerButtons,
  BannerButtonsStyles,
} from '../CookieConsentManagement/CookieConsentDomain/customize-banner';
import { AdobeLaunchConsentManager } from './adobe-launch-consent-manager';
import { ConsentState, CookieBlockingManager, CookieConsentState } from './cookie-blocking-manager';
import styles from './CookieBanner.module.css';
import DraggableLogo from './DraggableLogo';
import { GTMConsentManager } from './gtm-consent-manager';

// Interfaces used by the component
interface CookieConsent {
  category_id: number;
  consent_record_id: number;
  consent_status: boolean;
  cookie_id: number;
  service_id?: number;
}

interface DeviceInfoData {
  browser: {
    name: string;
    version: string;
    user_agent: string;
  };
  operating_system: {
    name: string;
    version: string;
  };
  device: {
    type: string;
    is_mobile: boolean;
    is_tablet: boolean;
    is_desktop: boolean;
    vendor?: string;
    model?: string;
  };
  screen: {
    width: number;
    height: number;
    viewport_width: number;
    viewport_height: number;
    device_pixel_ratio: number;
  };
}

interface ResponseBody {
  domain_id: number;
  subject_identity: string;
  geolocation: string;
  continent: string;
  country: string;
  source: string;
  cookie_category_consent: CookieConsent[];
  device_info?: DeviceInfoData;
}

interface CookieProperties {
  cookie_id: number;
  cookie_key: string;
  vendor_name: string;
  cookie_type: string;
  description: string;
  expiration: string;
  consent: boolean;
  consent_record_id: number;
  service_id?: number;
  category_id?: number;
  category_name?: string;
  domain_id?: number;
  consent_status?: boolean; // Added consent status field
}

interface ServiceProperties {
  service_id: number;
  service_name: string;
  service_description: string;
  cookies: CookieProperties[];
}

interface CategoryConsentRecordProperties {
  services: ServiceProperties[];
  independent_cookies: CookieProperties[];
  category_id: number;
  category_name: string;
  category_description: string;
  category_necessary: boolean;
  is_marketing: boolean;
  category_unclassified: boolean;
  catefory_default_opt_out: boolean;
  domain_id: number;
  subject_identity: string;
}

interface UserDataProperties {
  language_code: string;
  banner_code: string;
  banner_configuration: any;
  banner_title: string;
  banner_description: string;
  category_consent_record: CategoryConsentRecordProperties[];
  compliance_policy_link: string;
  consent_version?: number; // Track when cookies are updated
}

export interface BannerDesign {
  consentTabHeading: string;
  detailsTabHeading: string;
  aboutTabHeading: string;
  bannerHeading: string;
  bannerDescription: string;
  detailsTabDescription?: string;
  buttons?: BannerButtons;
  buttonStyles?: BannerButtonsStyles;
  buttonOrder?: ('deny' | 'allowSelection' | 'allowAll')[];
  denyButtonLabel: string;
  allowSelectionButtonLabel: string;
  allowAllButtonLabel: string;
  saveChoicesButtonLabel: string;
  // Preference Modal Button Configuration (for footer layout dialog)
  preferenceModalButtons?: BannerButtons;
  preferenceModalButtonStyles?: BannerButtonsStyles;
  preferenceModalButtonOrder?: ('deny' | 'allowSelection' | 'allowAll')[];
  preferenceModalDenyButtonLabel?: string;
  preferenceModalSaveChoicesButtonLabel?: string;
  preferenceModalAllowAllButtonLabel?: string;
  aboutSectionContent: string;
  backgroundColor: string;
  fontColor: string;
  textSize: string;
  fontFamily: string;
  cookiePolicyUrl: string;
  logoUrl: string;
  logoSize: { width: string; height: string };
  colorScheme: string;
  buttonColor: string;
  showLogo: string;
  layoutType: 'wall' | 'footer';
  privacyPolicyUrl?: string;
  showLanguageDropdown: boolean;
  automaticLanguageDetection: boolean;
  defaultOptIn: boolean;
  allowBannerClose: boolean;
}

export interface BannerConfigurations {
  bannerDesign: BannerDesign;
}

// interface TranslationRequestBody {
//   q: string;
//   target: string;
// }

// interface TranslationResponse {
//   data: {
//     translations: {
//       translatedText: string;
//     }[];
//   };
// }

interface Language {
  language_code: string;
  language: string;
}
// Interface for device and browser information
interface DeviceInfo {
  browserName: string;
  browserVersion: string;
  deviceType: string;
  osName: string;
  osVersion: string;
  isMobile: boolean;
  isTablet: boolean;
  isDesktop: boolean;
  mobileVendor?: string;
  mobileModel?: string;
  userAgent: string;
  screenWidth: number;
  screenHeight: number;
  viewportWidth: number;
  viewportHeight: number;
  devicePixelRatio: number;
}

// New prop interface – we expect a domain URL from the embed code
interface CookieBannerProps {
  domainUrl: string;
  environment: string;
  domain_id?: number;
}

function useDecodeGate(imgRef: React.RefObject<HTMLImageElement | null>, enabled = true) {
  const [ready, setReady] = useState(!enabled); // if no image, we’re ready
  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        await imgRef?.current?.decode?.();
      } catch {}
      if (!cancelled) setReady(true);
    })();
    return () => {
      cancelled = true;
    };
  }, [enabled]);
  return ready;
}

// Loader component for wall banner
const WallBannerLoader = () => (
  <div className={styles.cookieSkeletonLoader}>
    <div className={styles.cookieSkeletonHeader}>
      <div className={styles.cookieSkeletonLogo}></div>
      <div className={styles.cookieSkeletonLanguage}></div>
    </div>
    <div className={styles.cookieSkeletonTabs}>
      <div className={styles.cookieSkeletonTab}></div>
      <div className={styles.cookieSkeletonTab}></div>
      <div className={styles.cookieSkeletonTab}></div>
    </div>
    <div className={styles.cookieSkeletonContent}>
      <div className={styles.cookieSkeletonLine}></div>
      <div className={styles.cookieSkeletonLine}></div>
      <div className={styles.cookieSkeletonLine}></div>
    </div>
    <div className={styles.cookieSkeletonButtons}>
      <div className={styles.cookieSkeletonButton}></div>
      <div className={styles.cookieSkeletonButton}></div>
      <div className={styles.cookieSkeletonButton}></div>
    </div>
  </div>
);

// Loader component for footer banner
const FooterBannerLoader = () => (
  <div className={styles.cookieLoader}>
    <div className={styles.cookieLoaderSpinner}></div>
    <div className={styles.cookieLoaderText}>Loading cookie data...</div>
    <div className={styles.cookieLoaderSubtext}>Please wait while we prepare your options</div>
  </div>
);

type ConsentByCategory = { [categoryId: number]: boolean };

function getConsentBySlug(
  consentsByCategory: ConsentByCategory,
  slug: 'necessary' | 'analytics' | 'marketing' | 'functional' | 'performance',
  data: {
    category_consent_record?: Array<{
      category_id: number;
      category_name: string;
      category_necessary: boolean;
      is_marketing: boolean;
    }>;
  } | null
): boolean {
  if (!data?.category_consent_record?.length) {
    // No schema yet → be conservative
    return slug === 'necessary' ? true : false;
  }

  const recs = data.category_consent_record;

  // Helper to read current consent for a found record (defensive defaults)
  const read = (rec?: { category_id: number; category_necessary: boolean }) =>
    rec ? (rec.category_necessary ? true : !!consentsByCategory[rec.category_id]) : false;

  // Necessary (always true)
  if (slug === 'necessary') {
    // If you want to hard-force necessary to true regardless of toggle:
    return true;
  }

  // Marketing: prefer explicit flag, then name patterns
  if (slug === 'marketing') {
    const byFlag = recs.find((r) => r.is_marketing);
    if (byFlag) return read(byFlag);
    const byName = recs.find((r) => /marketing|advert|ads|promotion/i.test(r.category_name));
    return read(byName);
  }

  // Functional / Preferences
  if (slug === 'functional') {
    const byName = recs.find((r) => /functional|preference|functionality/i.test(r.category_name));
    return read(byName);
  }

  // Performance / Measurement
  if (slug === 'performance') {
    const byName = recs.find((r) =>
      /performance|measure|telemetry|apm|speed/i.test(r.category_name)
    );
    return read(byName);
  }

  // Analytics / Statistics
  if (slug === 'analytics') {
    const byName = recs.find((r) =>
      /analytic|statistic|measurement|insight/i.test(r.category_name)
    );
    return read(byName);
  }

  return false;
}

function persistConsentCookie(
  {
    subjectIdentity,
    domainId,
    domainURL,
    cookieUserData,
  }: {
    subjectIdentity: string;
    domainId: number;
    domainURL: string;
    cookieUserData: UserDataProperties | null;
  },
  {
    consentedCookieIds,
    allAvailableCookieIds,
    consentsByCategory,
  }: {
    consentedCookieIds: string[];
    allAvailableCookieIds: string[];
    consentsByCategory: { [categoryId: number]: boolean };
  }
) {
  const map = {
    necessary: true,
    analytics: getConsentBySlug(consentsByCategory, 'analytics', cookieUserData),
    marketing: getConsentBySlug(consentsByCategory, 'marketing', cookieUserData),
    functional: getConsentBySlug(consentsByCategory, 'functional', cookieUserData),
    performance: getConsentBySlug(consentsByCategory, 'performance', cookieUserData),
  };

  const isHttps = location.protocol === 'https:';
  const isLocalhost = location.hostname === 'localhost' || location.hostname === '127.0.0.1';

  Cookies.set(
    'gotrust_pb_ydt',
    JSON.stringify({
      subject_identity: subjectIdentity,
      domain_id: domainId,
      domain_url: domainURL,
      consent_version: cookieUserData?.consent_version || 1,
      consented_cookies: consentedCookieIds,
      available_cookies: allAvailableCookieIds,
      // 👇 NEW: the shim reads this synchronously to enforce on next load
      category_choices: map,
    }),
    {
      expires: 365,
      sameSite: 'Lax',
      path: '/',
      secure: isHttps,
    }
  );
}

/*
================== ⚠️ ADVISORY ==================
! This is the bundled file for the Cookie Consent Banner.

!📌 IMPORTANT:
? Only use standard HTML elements and inline CSS inside this bundle.
? Do NOT use any external CSS classes or frameworks, as this bundle needs to remain fully self-contained.
? USE window.location instead of useLocation();

!!!!!!!!!!!!!!!!! If you are using any library then please mention it over here !!!!!!!!!!!!

📦 Build Command:
Run the following command to generate the bundle:
    pnpm webpack --config webpack.cookie.config.js

This ensures the banner can be embedded via <script> on any page without external dependencies.

===============================================
*/

const generateUUID = () => {
  if (crypto?.randomUUID) {
    return crypto.randomUUID(); // modern browsers & Node.js
  }

  // Fallback for older browsers
  const arr = new Uint8Array(16);
  crypto.getRandomValues(arr);

  // RFC-4122 version 4 formatting
  arr[6] = (arr[6] & 0x0f) | 0x40; // version 4
  arr[8] = (arr[8] & 0x3f) | 0x80; // variant 10

  const hex = [...arr].map((b) => b.toString(16).padStart(2, '0')).join('');
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
};

const CookieBanner: React.FC<CookieBannerProps> = ({ domainUrl, environment, domain_id }) => {
  // USE STATE
  // const allowedKeys = [
  //   'aboutSectionContent',
  //   'aboutTabHeading',
  //   'consentTabHeading',
  //   'allowAllButtonLabel',
  //   'allowSelectionButtonLabel',
  //   'banner_configuration',
  //   'bannerDesign',
  //   'bannerDescription',
  //   'bannerHeading',
  //   'denyButtonLabel',
  //   'detailsTabHeading',
  //   'category_consent_record',
  //   'category_description',
  //   'category_name',
  //   'banner_title',
  //   'banner_description',
  //   'service_name',
  //   'service_description',
  //   'description',
  // ];
  const [domainData, setDomainData] = useState<UserDataProperties[]>();
  const [isVisible, setIsVisible] = useState(false);
  const [showFloatingLogo, setShowFloatingLogo] = useState(false);
  const [selectedNavItem, setSelectedNavItem] = useState<number>(1);
  const [countryCode, setCountryCode] = useState<string>('');
  const [countryName, setCountryName] = useState<string>('');
  const [continent, setContinent] = useState<string>('');
  const [domainId, setDomainId] = useState<number>(Number(domain_id));
  const [domainURL, setDomainURL] = useState<string>(domainUrl);
  const [subjectIdentity, setSubjectIdentity] = useState<string>('');
  const [translatedData, setTranslatedData] = useState<UserDataProperties>();
  const [cookies, setCookies] = useState<CookieProperties[]>(); // gives the list of cookies for that particular domain.
  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [ip, setIP] = useState('');
  // State to track user consent for each cookie
  const [userConsent, setUserConsent] = useState<{ [cookieId: number]: boolean }>({});
  const [categoryConsent, setCategoryConsent] = useState<{ [categoryId: number]: boolean }>({});
  const [openCookieWallBanner, setOpenCookieWallBanner] = useState(false);
  const [selectedLanguage, setSelectedLanguage] = useState('en');
  const [languages, setLanguages] = useState<Language[]>([]);
  const [position, setPosition] = useState<{ x: number; y: number }>({ x: 0, y: 0 });
  const [gtmManager, setGtmManager] = useState<GTMConsentManager | null>(null);
  const [adobeLaunchManager, setAdobeLaunchManager] = useState<AdobeLaunchConsentManager | null>(
    null
  );
  const [deviceInfo, setDeviceInfo] = useState<DeviceInfo | null>(null);
  const [cookieBlockingManager, setCookieBlockingManager] = useState<CookieBlockingManager | null>(
    null
  );
  const [apiCookieUserData, setApiCookieUserData] = useState<UserDataProperties | null>(null); // Data from API only
  const [localCookieUserData, setLocalCookieUserData] = useState<UserDataProperties | null>(null); // Local state updates
  const [isAnimating, setIsAnimating] = useState(false);
  const [contentKey, setContentKey] = useState(0); // Force re-render for content animations
  const [isLoadingTranslations, setIsLoadingTranslations] = useState(false); // Loading state for translations

  // Computed value: use local state if available, otherwise API state
  const cookieUserData = localCookieUserData || apiCookieUserData;

  const buttonColor = cookieUserData?.banner_configuration?.bannerDesign?.colorScheme || '#1032CF';
  const buttonsCfg = cookieUserData?.banner_configuration?.bannerDesign?.buttons ?? {
    deny: true,
    allowSelection: true,
    allowAll: true,
  };

  const isTabletOrAbove = useMediaQuery({ query: '(min-width: 768px)' });
  const isMobileDevice = useMediaQuery({ query: '(max-width: 767px)' });
  const isSmallMobile = useMediaQuery({ query: '(max-width: 480px)' });
  const apiResponseTimeRef = useRef<number>(0);
  const bannerVisibleTimeRef = useRef<number | null>(null);
  const userReactionTimeRef = useRef<number>(0);

  const wallRef = useRef<HTMLDivElement>(null);
  const footerRef = useRef<HTMLDivElement>(null);
  const logoRef = useRef<HTMLImageElement>(null);

  // If there's a logo & it’s visible, we wait; otherwise we’re instantly ready
  const hasLogo =
    !!cookieUserData?.banner_configuration?.bannerDesign?.logoUrl &&
    cookieUserData?.banner_configuration?.bannerDesign?.showLogo === 'true';

  const wallReady = useDecodeGate(logoRef, hasLogo); // wait for decode if logo exists
  const footerReady = wallReady; // same asset used; if you use a different image in footer, create another ref/hook

  const hasAnyNonNecessaryConsent = React.useCallback(() => {
    if (!cookieUserData) return false;
    return cookieUserData.category_consent_record.some(
      (c) => !c.category_necessary && !!categoryConsent[c.category_id]
    );
  }, [cookieUserData, categoryConsent]);

  const functionalCategoryGranted = React.useMemo(() => {
    if (!cookieUserData) return false;
    const functionalCat = cookieUserData.category_consent_record.find((c) =>
      /functional|preference/i.test(c.category_name)
    );
    return functionalCat ? !!categoryConsent[functionalCat.category_id] : false;
  }, [cookieUserData, categoryConsent]);

  const buildEffectiveConsent = (
    raw: { [categoryId: number]: boolean },
    data: UserDataProperties | null,
    dntEnabled: boolean
  ): { [categoryId: number]: boolean } => {
    if (!data) return raw;
    const out: { [id: number]: boolean } = { ...raw };

    data.category_consent_record.forEach((cat) => {
      // Force-deny marketing if DNT is enabled
      if (dntEnabled && cat.is_marketing) {
        out[cat.category_id] = false;
      }
      // Always keep necessary granted (defensive)
      if (cat.category_necessary) {
        out[cat.category_id] = true;
      }
    });

    return out;
  };

  const pushConsentToShim = (consentsByCategory: { [categoryId: number]: boolean }) => {
    const map = {
      necessary: true,
      analytics: getConsentBySlug(consentsByCategory, 'analytics', cookieUserData),
      marketing: getConsentBySlug(consentsByCategory, 'marketing', cookieUserData),
      functional: getConsentBySlug(consentsByCategory, 'functional', cookieUserData),
      performance: getConsentBySlug(consentsByCategory, 'performance', cookieUserData),
    };
    (window as any).__gotrustShim?.updateConsent(map);
    (window as any).__gotrustShim?.flushAllowed();
  };

  // GA family helpers (covers _ga, _ga_*, _gid, _gat, etc.)
  const GA_COOKIE_PREFIXES = ['_ga', '_gid', '_gat'];

  function candidatePaths() {
    const parts = (location.pathname || '/').split('/');
    const paths: string[] = [];
    for (let i = parts.length; i > 0; i--) {
      const p = parts.slice(0, i).join('/') || '/';
      paths.push(p.endsWith('/') ? p : p + '/');
    }
    paths.push('/'); // always try root
    return Array.from(new Set(paths));
  }

  function candidateDomains(hostname: string): string[] {
    const parts = hostname.split('.').filter(Boolean);
    const out = new Set<string>();

    // exact host + dotted host
    out.add(hostname); // "www.gotrust.tech"
    out.add('.' + hostname); // ".www.gotrust.tech"

    // apex (eTLD+1)
    if (parts.length >= 2) {
      const apex = parts.slice(-2).join('.'); // "gotrust.tech"
      out.add(apex);
      out.add('.' + apex);
    }

    // one level up if you ever run on deeper subs (optional)
    if (parts.length >= 3) {
      const lvl3 = parts.slice(-3).join('.');
      out.add(lvl3);
      out.add('.' + lvl3);
    }

    return Array.from(out);
  }

  function deleteCookieEverywhere(name: string) {
    // ⚠️ SAFEGUARD: Only delete known tracker cookies, never session/CSRF/cart cookies
    const TRACKER_PATTERNS =
      /^(_ga|_gid|_gat|_gcl|_gac|_fbp|_fbc|_hj|hjSession|_clck|_clsk|fs_|dt|rx|mmapi|ajs_|amplitude_|_ttp|_pin_unauth|IDE|test_cookie|NID|1P_JAR|ANID|DSID|FLC|AID|TAID)/i;

    // NEVER delete these critical cookies
    const PROTECTED_PATTERNS =
      /^(sessionid|PHPSESSID|connect\.sid|csrftoken|XSRF-TOKEN|__Secure-|__Host-|gotrust_pb_ydt|auth|login|cart|basket|order)/i;

    if (PROTECTED_PATTERNS.test(name)) {
      console.warn('[GoTrust] Refusing to delete protected cookie:', name);
      return; // ← SAFETY EXIT
    }

    if (!TRACKER_PATTERNS.test(name)) {
      console.warn('[GoTrust] Refusing to delete non-tracker cookie:', name);
      return; // ← SAFETY EXIT
    }

    const domains = candidateDomains(location.hostname);
    const paths = candidatePaths();

    // try with different SameSite/Secure combos
    const variants = ['', 'SameSite=Lax', 'SameSite=None; Secure'];

    const nuke = (domain: string | null, path: string, extra: string) => {
      const dom = domain ? `Domain=${domain}; ` : '';
      const exp = 'Expires=Thu, 01 Jan 1970 00:00:00 GMT; Max-Age=0;';
      const pth = `Path=${path}; `;
      document.cookie = `${name}=; ${exp} ${pth}${dom}${extra}`.replace(/\s+;/g, ';').trim();
    };

    // domain+path attempts
    domains.forEach((d) => paths.forEach((p) => variants.forEach((v) => nuke(d, p, v))));
    // host-only attempts (no Domain attr)
    paths.forEach((p) => variants.forEach((v) => nuke(null, p, v)));
  }

  // convenience for GA cookies
  function purgeGoogleAnalyticsCookies() {
    // GA4 (_ga, _ga_*, legacy variants)
    const names = ['_ga', '_ga_0', '_ga_1', '_ga_L193CBVT22']; // include your property-specific _ga_* names if known
    // delete generic pattern too
    const jar = document.cookie.split(';').map((c) => c.trim().split('=')[0]);
    jar.forEach((n) => {
      if (n === '_ga' || /^_ga_/.test(n)) names.push(n);
    });
    Array.from(new Set(names)).forEach(deleteCookieEverywhere);
  }

  function purgeCookiesForDeniedCategories(
    consentsByCategory: { [categoryId: number]: boolean },
    data: UserDataProperties | null
  ) {
    if (!data) return;
    const namesToDelete = new Set<string>();

    data.category_consent_record.forEach((cat) => {
      const granted = !!consentsByCategory[cat.category_id] || !!cat.category_necessary;
      if (granted) return; // keep
      // collect all cookie keys under this denied category
      cat.services?.forEach((s) => s.cookies?.forEach((k) => namesToDelete.add(k.cookie_key)));
      cat.independent_cookies?.forEach((k) => namesToDelete.add(k.cookie_key));
    });

    // always include GA family if analytics is denied (covers GA’s standard names)
    const analyticsCat = data.category_consent_record.find((c) =>
      /analytic|statistic|measurement|insight/i.test(c.category_name)
    );
    if (analyticsCat && !consentsByCategory[analyticsCat.category_id]) {
      document.cookie.split(';').forEach((c) => {
        const n = c.split('=')[0].trim();
        if (GA_COOKIE_PREFIXES.some((p) => n === p || n.startsWith(p + '_'))) {
          namesToDelete.add(n);
        }
      });
    }

    namesToDelete.forEach(deleteCookieEverywhere);
  }

  const baseURL = environment;
  // Use bannerDesign values based on screen size
  const bannerStyles = isTabletOrAbove
    ? {
        backgroundColor:
          cookieUserData?.banner_configuration?.bannerDesign?.backgroundColor ?? 'white',
        color: cookieUserData?.banner_configuration?.bannerDesign?.fontColor ?? 'black',
        fontFamily: getFontFamilyWithFallbacks(
          cookieUserData?.banner_configuration?.bannerDesign?.fontFamily ?? 'Poppins'
        ),
        fontSize:
          cookieUserData?.banner_configuration?.bannerDesign?.textSize === 'small'
            ? '12px'
            : cookieUserData?.banner_configuration?.bannerDesign?.textSize === 'medium'
              ? '16px'
              : '20px',
      }
    : {
        backgroundColor:
          cookieUserData?.banner_configuration?.bannerDesign?.backgroundColor ?? '#f8f8f8',
        color: cookieUserData?.banner_configuration?.bannerDesign?.fontColor ?? '#333',
        fontFamily: getFontFamilyWithFallbacks(
          cookieUserData?.banner_configuration?.bannerDesign?.fontFamily ?? 'Poppins'
        ),
        fontSize: '14px',
      };

  const isDoNotTrackEnabled = navigator.doNotTrack === '1' || navigator.doNotTrack === 'yes';

  const btnBase: React.CSSProperties = {
    color: 'white',
    backgroundColor: buttonColor,
    border: 'none',
    borderRadius: '6px',
    fontWeight: 600,
    fontFamily: bannerStyles.fontFamily ?? 'sans-serif',
    lineHeight: 1,
    textAlign: 'center',
    cursor: 'pointer',
    transition: 'opacity .2s ease, transform .2s ease',
    // responsive sizing (desktop)
    height: 'clamp(32px, 5.2vw, 44px)',
    padding: '0 clamp(8px, 1.1vw, 12px)',
    fontSize: 'clamp(11px, 1.05vw, 13px)',
    // keep in one line and allow shrinking
    whiteSpace: 'nowrap',
    minWidth: 0,
    flexShrink: 1,
    overflow: 'hidden',
    textOverflow: 'ellipsis',
    transform: 'translateY(0)',
  };

  // Function to collect device and browser information
  const collectDeviceInfo = () => {
    // Get viewport dimensions
    const viewportWidth = Math.max(
      document.documentElement.clientWidth || 0,
      window.innerWidth || 0
    );
    const viewportHeight = Math.max(
      document.documentElement.clientHeight || 0,
      window.innerHeight || 0
    );

    // Create device info object
    const info: DeviceInfo = {
      browserName: browserName,
      browserVersion: browserVersion,
      deviceType: deviceType,
      osName: osName,
      osVersion: osVersion,
      isMobile: isMobile,
      isTablet: isTablet,
      isDesktop: isDesktop,
      userAgent: navigator.userAgent,
      screenWidth: window.screen.width,
      screenHeight: window.screen.height,
      viewportWidth: viewportWidth,
      viewportHeight: viewportHeight,
      devicePixelRatio: window.devicePixelRatio || 1,
    };

    // Add mobile-specific information if available
    if (isMobile || isTablet) {
      info.mobileVendor = mobileVendor;
      info.mobileModel = mobileModel;
    }

    setDeviceInfo(info);
    return info;
  };

  // Call this when banner is shown
  function onBannerVisible() {
    // only send calculate the time on first interaction
    if (Cookies.get('gotrust_pb_ydt')) {
      return;
    }
    bannerVisibleTimeRef.current = performance.now();
  }

  // Call this inside button click handler
  function onBannerButtonClick() {
    // only send calculate the time on first interaction
    if (Cookies.get('gotrust_pb_ydt')) {
      return;
    }
    if (bannerVisibleTimeRef.current) {
      userReactionTimeRef.current = performance.now() - bannerVisibleTimeRef.current;
      sendAPIResponseMetric();
    }
  }

  useEffect(() => {
    // Expose the function globally
    (window as any).showGoTrustCookiePreferences = (value: boolean) => {
      setIsDialogOpen(value);
      setIsVisible(value);
    };

    // Cleanup on unmount
    return () => {
      delete (window as any).showGoTrustCookiePreferences;
    };
  }, []);

  useEffect(() => {
    // Collect device information when component mounts
    collectDeviceInfo();
    // const deviceData = collectDeviceInfo();
    // Cookies.set('device_info', JSON.stringify(deviceData), {
    //   sameSite: 'Strict',
    //   path: '/',
    // });
  }, []);

  useEffect(() => {
    if (cookieUserData) {
      if (
        cookieUserData?.banner_configuration?.bannerDesign?.automaticLanguageDetection &&
        languages.some((lang) => lang.language_code === navigator.language.split('-')[0])
      ) {
        setSelectedLanguage(navigator.language.split('-')[0]);
      }
    }
  }, [cookieUserData, languages]);

  // Load font when font family changes
  useEffect(() => {
    const fontFamily = cookieUserData?.banner_configuration?.bannerDesign?.fontFamily;
    if (fontFamily && functionalCategoryGranted) {
      loadGoogleFont(fontFamily).catch((error) => {
        console.warn(`Failed to load font "${fontFamily}":`, error);
      });
    }
  }, [cookieUserData?.banner_configuration?.bannerDesign?.fontFamily, functionalCategoryGranted]);

  // !! Fetch IP and country code only for customers
  // useEffect(() => {
  //   const getData = async () => {
  //     const ipRes = await axios.get('https://api.ipify.org?format=json');
  //     const ip = ipRes.data.ip;
  //     const geoRes = await axios.get(`${baseURL}/backend/api/v1/ip-info/${ip}`);
  //     setIP(ip);
  //     setCountryCode(geoRes?.data?.result?.countryCode ?? 'IN');
  //     setCountryName(geoRes?.data?.result?.countryName ?? 'India');
  //     setContinent(geoRes?.data?.result?.continentName ?? 'Asia');
  //   };

  //   getData();
  // }, []);

  // !! Fetch IP and country code only for gotrust environments
  useEffect(() => {
    const getData = async () => {
      const ipRes = await axios.get('https://api.ipify.org?format=json');
      const ip = ipRes?.data?.ip;
      const response = await axios.get(`${baseURL}/backend/api/v3/gt/ip-info/${ip}`);
      const geoRes = response?.data?.result;
      setIP(ip);
      setCountryCode(geoRes?.data?.country_code ?? 'IN');
      setCountryName(geoRes?.data?.country ?? 'India');
      setContinent(geoRes?.data?.continent ?? 'Asia');
    };

    getData();
  }, []);

  // !! Fetch IP and country code only for gotrust environments
  // useEffect(() => {
  //   const getData = async () => {
  //     const ipRes = await axios.get('https://api.ipify.org?format=json');
  //     const ip = ipRes?.data?.ip;
  //     const response = await axios.get(`${baseURL}/backend/api/v3/gt/ip-info/${ip}`);
  //     const geoRes = response?.data?.result;
  //     setIP(ip ?? '106.219.162.116');
  //     setCountryCode(geoRes?.data?.country_code ?? 'IN');
  //     setCountryName(geoRes?.data?.country ?? 'India');
  //     setContinent(geoRes?.data?.continent ?? 'Asia');
  //   };

  //   getData();
  // }, []);

  // Check if our cookie is present to decide whether to show the banner and call the ping API
  useEffect(() => {
    const cookieDetails = Cookies.get('gotrust_pb_ydt');
    if (cookieDetails) {
      const cookieData = JSON.parse(cookieDetails);
      if (cookieData?.subject_identity && cookieData?.domain_id && cookieData?.domain_url) {
        setSubjectIdentity(cookieData.subject_identity);
        setDomainId(cookieData.domain_id);
        setDomainURL(cookieData.domain_url);
        setIsVisible(false);
        setShowFloatingLogo(true);
        if (countryName) fetchUserData(cookieData.subject_identity);
      }
    } else {
      const uuid = generateUUID();
      setSubjectIdentity(uuid);
      if (countryName) fetchUserDataCDN();
      setIsVisible(true);
    }
  }, [countryName]);

  // Check for new cookies ONLY when API data changes (not local state updates)
  useEffect(() => {
    if (apiCookieUserData && domainId) {
      checkForNewCookies();
    }
  }, [apiCookieUserData, subjectIdentity, domainId]);

  // Handle language changes separately - only fetch translations, don't refetch user data
  useEffect(() => {
    if (selectedLanguage !== 'en' && apiCookieUserData) {
      // Only fetch translations if we have API data and language is not English
      getTranslatedData(selectedLanguage);
    } else if (selectedLanguage === 'en') {
      // Clear translated data when switching back to English
      setTranslatedData(undefined);
    }
  }, [selectedLanguage, apiCookieUserData]);

  // Initialize GTM when cookie user data is loaded
  useEffect(() => {
    try {
      if (cookieUserData?.banner_configuration) {
        const gtmConfig = cookieUserData.banner_configuration.gtmConfiguration;
        const gtmMappings = Array.isArray(cookieUserData.banner_configuration.gtmCategoryMappings)
          ? cookieUserData.banner_configuration.gtmCategoryMappings
          : [];

        if (gtmConfig) {
          const manager = new GTMConsentManager(gtmConfig, gtmMappings);
          setGtmManager(manager);

          if (gtmConfig.enabled) {
            // Seeds default deny in dataLayer; does NOT inject script in our updated manager
            manager.initialize();
          }
        }
      }
    } catch (error) {
      console.error('Error initializing GTM consent manager:', error);
    }
  }, [cookieUserData]);

  // Initialize Adobe Launch when cookie user data is loaded
  useEffect(() => {
    try {
      if (cookieUserData?.banner_configuration) {
        const adobeLaunchConfig = cookieUserData.banner_configuration.adobeLaunchConfiguration;
        const adobeLaunchMappings = Array.isArray(
          cookieUserData.banner_configuration.adobeLaunchCategoryMappings
        )
          ? cookieUserData.banner_configuration.adobeLaunchCategoryMappings
          : [];

        if (adobeLaunchConfig) {
          const manager = new AdobeLaunchConsentManager(adobeLaunchConfig, adobeLaunchMappings);
          setAdobeLaunchManager(manager);

          if (adobeLaunchConfig.enabled) {
            // Seeds default deny in _satellite.privacy; does NOT inject library
            manager.initialize();
          }
        }
      }
    } catch (error) {
      console.error('Error initializing Adobe Launch consent manager:', error);
    }
  }, [cookieUserData]);

  // Initialize Cookie Blocking Manager when cookieUserData is loaded
  useEffect(() => {
    try {
      if (cookieUserData?.category_consent_record) {
        // tear down the baseline instance (if any)
        if (cookieBlockingManager) cookieBlockingManager.destroy();

        const blockingConfig = CookieBlockingManager.createConfigFromApiData(
          cookieUserData.category_consent_record,
          true
        );

        const mgr = new CookieBlockingManager(blockingConfig);
        setCookieBlockingManager(mgr);

        // Initial deny-all except necessary
        const initialConsentState: ConsentState = {};
        cookieUserData.category_consent_record.forEach((category) => {
          initialConsentState[category.category_id] = !!category.category_necessary;
        });
        mgr.updateConsent(initialConsentState);

        // 🔄 COORDINATION: Sync initial state with shim
        if ((window as any).__gotrustShim) {
          const shimConsent = {
            necessary: true,
            analytics: getConsentBySlug(initialConsentState, 'analytics', cookieUserData),
            marketing: getConsentBySlug(initialConsentState, 'marketing', cookieUserData),
            functional: getConsentBySlug(initialConsentState, 'functional', cookieUserData),
            performance: getConsentBySlug(initialConsentState, 'performance', cookieUserData),
          };
          (window as any).__gotrustShim.updateConsent(shimConsent);
        }

        return () => mgr.destroy();
      }
    } catch (error) {
      console.error('Error initializing cookie blocking manager:', error);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [cookieUserData?.category_consent_record]);

  // Seed the toggles from stored consent + API data on load
  useEffect(() => {
    if (!cookieUserData) return;

    const cookieDetails = Cookies.get('gotrust_pb_ydt');
    const hasStoredCookie = !!cookieDetails;

    const initialCategoryConsent: { [id: number]: boolean } = {};
    const initialUserConsent: { [id: number]: boolean } = {};

    cookieUserData.category_consent_record.forEach((category) => {
      const forcedNecessary = !!category.category_necessary;
      const marketingDntBlock = isDoNotTrackEnabled && category.is_marketing;

      // if we have no stored cookie yet, respect default opt-out flag
      const useDefaultOptOut = !hasStoredCookie && category.catefory_default_opt_out;

      // server-side consent snapshot
      const anyCookieConsentedOnServer =
        category.services?.some((s) => s.cookies?.some((k) => !!k.consent)) ||
        category.independent_cookies?.some((k) => !!k.consent);

      // final category-level decision for UI
      const categoryGranted = forcedNecessary
        ? true
        : marketingDntBlock
          ? false
          : useDefaultOptOut
            ? true // If default opt-out is true, then toggle should be ON by default
            : anyCookieConsentedOnServer;

      initialCategoryConsent[category.category_id] = categoryGranted;

      // per-cookie switches
      category.services?.forEach((s) =>
        s.cookies?.forEach((k) => {
          initialUserConsent[k.cookie_id] = forcedNecessary
            ? true
            : useDefaultOptOut
              ? true // If default opt-out is true, then individual cookies should be ON by default
              : !!k.consent;
        })
      );
      category.independent_cookies?.forEach((k) => {
        initialUserConsent[k.cookie_id] = forcedNecessary
          ? true
          : useDefaultOptOut
            ? true // If default opt-out is true, then individual cookies should be ON by default
            : !!k.consent;
      });
    });

    setCategoryConsent(initialCategoryConsent);
    setUserConsent(initialUserConsent);
  }, [cookieUserData, isDoNotTrackEnabled]);

  useEffect(() => {
    const cookieDetails = Cookies.get('gotrust_pb_ydt');
    if (!cookieDetails || !cookieUserData) return;

    // 1) Apply DNT to current category consents
    const effectiveConsent = buildEffectiveConsent(
      categoryConsent,
      cookieUserData,
      isDoNotTrackEnabled
    );

    // 2) Decide if we should load vendors (any non-necessary category effectively granted?)
    const anyGranted = cookieUserData.category_consent_record.some(
      (c) => !c.category_necessary && !!effectiveConsent[c.category_id]
    );

    // 3) Update managers and conditionally load
    try {
      if (gtmManager && cookieUserData?.banner_configuration?.gtmConfiguration?.enabled) {
        gtmManager.updateConsent(effectiveConsent);
        if (anyGranted) gtmManager.loadGTM(); // load only when something non-necessary is granted
      }
    } catch (e) {
      console.warn('GTM post-consent load failed:', e);
    }

    try {
      if (
        adobeLaunchManager &&
        cookieUserData?.banner_configuration?.adobeLaunchConfiguration?.enabled
      ) {
        adobeLaunchManager.updateConsent(effectiveConsent);
        if (anyGranted) adobeLaunchManager.loadAdobeLaunch();
      }
    } catch (e) {
      console.warn('Adobe post-consent load failed:', e);
    }
  }, [
    categoryConsent,
    cookieUserData,
    gtmManager,
    adobeLaunchManager,
    isDoNotTrackEnabled, // <-- include DNT in deps
  ]);

  const loadVendorsAfterConsent = React.useCallback(
    (consentByCategory: { [categoryId: number]: boolean }) => {
      // Should we load third-party containers?
      const anyGrantedNow =
        cookieUserData?.category_consent_record?.some(
          (c) => !c.category_necessary && consentByCategory[c.category_id]
        ) ?? false;

      try {
        if (gtmManager && cookieUserData?.banner_configuration?.gtmConfiguration?.enabled) {
          gtmManager.updateConsent(consentByCategory);
          if (anyGrantedNow) gtmManager.loadGTM();
        }
      } catch (e) {
        console.warn('GTM load after consent failed:', e);
      }

      try {
        if (
          adobeLaunchManager &&
          cookieUserData?.banner_configuration?.adobeLaunchConfiguration?.enabled
        ) {
          adobeLaunchManager.updateConsent(consentByCategory);
          if (anyGrantedNow) adobeLaunchManager.loadAdobeLaunch();
        }
      } catch (e) {
        console.warn('Adobe load after consent failed:', e);
      }
    },
    [cookieUserData, gtmManager, adobeLaunchManager]
  );

  useEffect(() => {
    const fetchLanguages = async () => {
      try {
        const response = await fetch(`${baseURL}/ucm/cp?domain_id=${domainId}`);
        const data = await response.json();
        setLanguages(data?.result?.data);
      } catch (error) {
        setLanguages([{ language_code: 'en', language: 'English' }]);
        console.error('Error fetching languages:', error);
      }
    };

    if (domainId) fetchLanguages();
  }, [domainId]);

  // const ping = async () => {
  //   try {
  //     // Make sure device info is collected
  //     const deviceData = deviceInfo || collectDeviceInfo();

  //     const response = await axios.post(`${baseURL}/ucm/v2/banner/record-per-user-initial-action`, {
  //       user_action: 'ping',
  //       domain_url: domainUrl,
  //       geolocation: `${ip}(${countryCode})`,
  //       continent,
  //       country: countryName,
  //       source: 'web',
  //       device_info: {
  //         browser: {
  //           name: deviceData.browserName,
  //           version: deviceData.browserVersion,
  //           user_agent: deviceData.userAgent,
  //         },
  //         operating_system: {
  //           name: deviceData.osName,
  //           version: deviceData.osVersion,
  //         },
  //         device: {
  //           type: deviceData.deviceType,
  //           is_mobile: deviceData.isMobile,
  //           is_tablet: deviceData.isTablet,
  //           is_desktop: deviceData.isDesktop,
  //           vendor: deviceData.mobileVendor,
  //           model: deviceData.mobileModel,
  //         },
  //         screen: {
  //           width: deviceData.screenWidth,
  //           height: deviceData.screenHeight,
  //           viewport_width: deviceData.viewportWidth,
  //           viewport_height: deviceData.viewportHeight,
  //           device_pixel_ratio: deviceData.devicePixelRatio,
  //         },
  //       },
  //     });

  //     if (response?.data?.result?.data?.length) {
  //       const data = response.data.result.data[0];
  //       setDomainId(data.domain_id);
  //       setDomainURL(data.domain_url);
  //       setSubjectIdentity(data.subject_identity);

  //       if (data.domain_url) {
  //         fetchCookies(data.domain_url);
  //       }
  //     }
  //   } catch (error) {
  //     if (axios.isAxiosError(error)) {
  //       console.error(
  //         `Error fetching data: ${error.response?.status} - ${error.response?.statusText}`
  //       );
  //     } else {
  //       console.error('An unexpected error occurred.');
  //     }
  //   }
  // };

  // Function to translate text
  const getTranslatedData = async (selectedLanguage: string) => {
    // Only show loading if we already have banner data (banner type is determined)
    if (cookieUserData) {
      setIsLoadingTranslations(true);
    }
    try {
      setTranslatedData(domainData?.find((item) => item?.language_code === selectedLanguage));
    } catch (error) {
    } finally {
      setIsLoadingTranslations(false);
    }
  };

  // Fetch cookies for the given domain
  const fetchCookies = async (domain_url: string) => {
    try {
      const params = new URLSearchParams({ domain_url });
      if (domainId) params.append('domain_id', domainId?.toString());

      const response = await axios.get(
        `${baseURL}/ucm/banner/horizontal-banner?${params.toString()}`
      );

      if (response?.data?.result?.data?.length) {
        const cookie_category_data = response.data.result.data;
        const domainCookies: CookieProperties[] = [];

        if (cookie_category_data) {
          for (const category of cookie_category_data) {
            if (category?.cookies?.length) {
              for (const cookie of category.cookies) {
                const cookieDetails = {
                  ...cookie,
                  category_id: category.category_id,
                  category_name: category.category_name,
                  domain_id: category.domain_id,
                  consent_status: cookie.consent || false, // Initialize consent_status based on current consent
                };
                domainCookies.push(cookieDetails);
              }
            }
          }
          setCookies(domainCookies);

          // Set total_cookies for backward compatibility with existing code
          localStorage.setItem('total_cookies', JSON.stringify(domainCookies));
          // Removed setEssentialCookies call - CookieBlockingManager handles this
        }
      }
    } catch (error) {
      if (axios.isAxiosError(error)) {
        console.error(
          `Error fetching Cookies: ${error.response?.status} - ${error.response?.statusText}`
        );
      } else {
        console.error('An unexpected error occurred.');
      }
    }
  };

  const fetchUserData = async (subjectIdentity: string) => {
    try {
      // Start time
      const apiStart = performance.now();

      const response = await axios.get(
        `${baseURL}/ucm/v2/banner/display?domain_id=${domainId}&subject_identity=${subjectIdentity}&country_name=${countryName}`
      );

      // End time
      const apiEnd = performance.now();
      apiResponseTimeRef.current = apiEnd - apiStart; // ms

      // Always set API data first (this will trigger new cookie detection)
      setApiCookieUserData(response.data.result.data[0]);
      // timer start when banner is shown
      onBannerVisible();
      // Clear any local state to use fresh API data
      setLocalCookieUserData(null);

      const { category_consent_record } = response.data.result.data[0];
      if (category_consent_record?.length) {
        setCategoryConsentStatus(category_consent_record); // ✅ Add this line
      }

      // Note: Translation handling is now done in a separate useEffect
      // This prevents the English API from overriding translated data

      if (response.data.result.data[0].banner_configuration.bannerDesign.layoutType === 'wall') {
        setOpenCookieWallBanner(true);
      }
    } catch (error) {
      console.error('Error fetching user data:', error);
    }
  };

  const fetchUserDataCDN = async () => {
    try {
      // Start time
      const apiStart = performance.now();

      const response = await axios.get(
        `https://d1axzsitviir9s.cloudfront.net/banner/${domainURL.replace(/[\/\\]/g, '')}_${domainId}.json`
      );

      // End time
      const apiEnd = performance.now();
      apiResponseTimeRef.current = apiEnd - apiStart; // ms

      // Always set API data first (this will trigger new cookie detection)
      setApiCookieUserData(
        response.data.result.data?.find((item: UserDataProperties) => item?.language_code === 'en')
      );
      setDomainData(response.data.result.data);
      // timer start when banner is shown
      onBannerVisible();
      // Clear any local state to use fresh API data
      setLocalCookieUserData(null);

      const { category_consent_record } = response.data.result.data[0];
      if (category_consent_record?.length) {
        setCategoryConsentStatus(category_consent_record); // ✅ Add this line
      }

      // Note: Translation handling is now done in a separate useEffect
      // This prevents the English API from overriding translated data

      if (response.data.result.data[0].banner_configuration.bannerDesign.layoutType === 'wall') {
        setOpenCookieWallBanner(true);
      }
    } catch (error) {
      console.error('Error fetching user data:', error);
    }
  };

  // Helper functions to build consent arrays and set cookies
  const addCookiesToConsentArray = (
    cookies: CookieProperties[],
    categoryId: number,
    consentStatus: boolean,
    serviceId?: number
  ): CookieConsent[] => {
    return cookies.map((cookie) => ({
      category_id: categoryId,
      consent_record_id: cookie.consent_record_id,
      consent_status: consentStatus,
      cookie_id: cookie.cookie_id,
      ...(serviceId && { service_id: serviceId }),
    }));
  };

  // Removed setEssentialCookies - let CookieBlockingManager handle all cookie management

  const setUserConsentCookies = (cookieConsentArray: CookieConsent[]) => {
    const total_cookies = localStorage.getItem('total_cookies');
    if (total_cookies) {
      const parsedCookies: CookieProperties[] = JSON.parse(total_cookies);

      // Create a map of cookie consent for quick lookup
      const consentMap = new Map<number, boolean>();
      cookieConsentArray.forEach((consent) => {
        consentMap.set(consent.cookie_id, consent.consent_status);
      });

      // Update cookies with consent status (NO manual cookie setting)
      const updatedCookies = parsedCookies.map((cookie) => {
        const hasConsent = consentMap.get(cookie.cookie_id) || false;

        // Return updated cookie object with consent_status
        // Let CookieBlockingManager and tracking scripts handle actual cookies
        return {
          ...cookie,
          consent_status: hasConsent,
        };
      });

      // Update localStorage with consent status included
      localStorage.setItem('total_cookies', JSON.stringify(updatedCookies));
    }
  };

  const setCategoryConsentStatus = (categoryConsentRecord: CategoryConsentRecordProperties[]) => {
    const categories = categoryConsentRecord.map((category) => {
      // Determine if consent is given (based on cookies)
      const hasConsent =
        category.category_necessary ||
        category.services.some((service) =>
          service.cookies.some((cookie) => cookie.consent === true)
        ) ||
        category.independent_cookies.some((cookie) => cookie.consent === true);

      return {
        category_id: category.category_id,
        category_name: category.category_name,
        consent_status: hasConsent,
      };
    });

    localStorage.setItem('total_categories', JSON.stringify(categories));
  };

  const sendAPIResponseMetric = async () => {
    try {
      const response = await axios.post(`${baseURL}/ucm/v2/banner/load-time`, {
        domain_id: domainId,
        subject_identity: subjectIdentity,
        load_time: apiResponseTimeRef.current
          ? Number(apiResponseTimeRef.current.toFixed(2))
          : null, // ms API took

        response_time: userReactionTimeRef.current
          ? Number(userReactionTimeRef.current.toFixed(2))
          : null, // ms user took
      });
    } catch (error) {
      if (axios.isAxiosError(error)) {
        console.error(
          `Error fetching data: ${error.response?.status} - ${error.response?.statusText}`
        );
      } else {
        console.error('An unexpected error occurred.');
      }
    }
  };

  // HANDLER FUNCTIONS

  /**
   * Update local cookieUserData state to reflect user consent choices
   * This avoids needing to call the API again and prevents triggering new cookie detection
   */
  const updateLocalConsentState = (cookieConsentArray: CookieConsent[]) => {
    if (!apiCookieUserData) return;

    // Create a map of cookie consent for quick lookup
    const consentMap = new Map<number, boolean>();
    cookieConsentArray.forEach((consent) => {
      consentMap.set(consent.cookie_id, consent.consent_status);
    });

    // Update the API data with new consent states and set as local state
    const updatedCookieUserData = {
      ...apiCookieUserData,
      category_consent_record: apiCookieUserData.category_consent_record.map((category) => ({
        ...category,
        services: category.services.map((service) => ({
          ...service,
          cookies: service.cookies.map((cookie) => ({
            ...cookie,
            consent: consentMap.get(cookie.cookie_id) ?? cookie.consent,
          })),
        })),
        independent_cookies: category.independent_cookies.map((cookie) => ({
          ...cookie,
          consent: consentMap.get(cookie.cookie_id) ?? cookie.consent,
        })),
      })),
    };

    // Set as local state (this won't trigger new cookie detection)
    setLocalCookieUserData(updatedCookieUserData);

    // ✅ Update localStorage for category consent status
    setCategoryConsentStatus(updatedCookieUserData.category_consent_record);
  };

  /**
   * Check if new cookies have been added since last consent
   * Uses total_cookies from localStorage to determine what cookies were available
   * when user last gave consent, and compares with current API data
   */
  const checkForNewCookies = () => {
    try {
      const cookieDetails = Cookies.get('gotrust_pb_ydt');
      if (!cookieDetails || !apiCookieUserData) return; // Only check against API data

      const storedConsentData = JSON.parse(cookieDetails);
      const storedVersion = storedConsentData.consent_version || 1;
      const currentVersion = apiCookieUserData.consent_version || 1;

      // Get the list of cookies that were available when consent was last given
      // Use available_cookies from gotrust_pb_ydt cookie which contains ALL cookies that were available
      const storedAvailableCookies =
        storedConsentData.available_cookies || storedConsentData.consented_cookies || [];

      // If no available_cookies data, this might be an old cookie format, don't show banner
      if (!storedAvailableCookies || storedAvailableCookies.length === 0) {
        return;
      }

      // Get all current cookie IDs from API
      const currentCookieIds: string[] = [];
      apiCookieUserData.category_consent_record.forEach((category) => {
        category.services.forEach((service) => {
          service.cookies.forEach((cookie) => {
            currentCookieIds.push(cookie.cookie_id.toString());
          });
        });
        category.independent_cookies.forEach((cookie) => {
          currentCookieIds.push(cookie.cookie_id.toString());
        });
      });

      // Check if version has changed OR truly new cookies have been added
      // Only consider cookies "new" if they weren't available during last consent
      const newCookies = currentCookieIds.filter((id) => !storedAvailableCookies.includes(id));
      const hasNewCookies = newCookies.length > 0;
      const versionChanged = currentVersion > storedVersion;

      if (hasNewCookies || versionChanged) {
        // Clear old consent and show banner
        Cookies.remove('gotrust_pb_ydt');
        setIsVisible(true);
        setShowFloatingLogo(false);
        setOpenCookieWallBanner(true);
      }
    } catch (error) {
      console.error('Error checking for new cookies:', error);
    }
  };

  const handleClose = () => {
    const existingCookie = Cookies.get('gotrust_pb_ydt');
    const defaultOptIn = cookieUserData?.banner_configuration?.bannerDesign?.defaultOptIn;

    // If no existing cookie (first-time user), perform action based on defaultOptIn
    if (!existingCookie) {
      if (defaultOptIn) {
        // defaultOptIn = true -> perform deny action
        handleRejectAllCookies();
      } else {
        // defaultOptIn = false -> perform allow all action
        handleAcceptAllCookies();
      }
      return;
    }

    // If cookie exists, just close the banner
    setIsVisible(false);
    setShowFloatingLogo(true);
    setOpenCookieWallBanner(false);
    setSelectedNavItem(1); // Reset to initial tab when closing
  };

  const handleOpenDialog = (e: React.MouseEvent) => {
    e?.preventDefault();
    setIsDialogOpen(true);
    setIsVisible(true);
  };

  const handleNavbar = (value: number) => {
    setIsAnimating(true);
    setSelectedNavItem(value);
    setContentKey((prev) => prev + 1);
    setTimeout(() => setIsAnimating(false), 400);
  };

  const handleCookieConsentChange = (cookieId: number, consent: boolean) => {
    setUserConsent((prev) => ({
      ...prev,
      [cookieId]: consent,
    }));

    if (cookieUserData) {
      const category = cookieUserData.category_consent_record.find(
        (cat) =>
          cat.services.some((service) =>
            service.cookies.some((cookie) => cookie.cookie_id === cookieId)
          ) || cat.independent_cookies.some((cookie) => cookie.cookie_id === cookieId)
      );

      if (category) {
        const allCookiesInCategory = [
          ...category.services.flatMap((service) => service.cookies),
          ...category.independent_cookies,
        ];

        const isAnyCookieTrue = allCookiesInCategory.some((cookie) =>
          cookie.cookie_id === cookieId ? consent : userConsent[cookie.cookie_id]
        );

        setCategoryConsent((prev) => ({
          ...prev,
          [category.category_id]: isAnyCookieTrue,
        }));
      }
    }
  };

  const handleCategoryConsentChange = (
    categoryId: number,
    consent: boolean,
    category: CategoryConsentRecordProperties
  ) => {
    setCategoryConsent((prev) => ({
      ...prev,
      [categoryId]: consent,
    }));

    const updatedUserConsent = { ...userConsent };

    for (const service of category.services) {
      for (const cookie of service.cookies) {
        updatedUserConsent[cookie.cookie_id] = consent;
      }
    }
    for (const cookie of category.independent_cookies) {
      updatedUserConsent[cookie.cookie_id] = consent;
    }
    setUserConsent(updatedUserConsent);
  };

  //? Reject All
  const handleRejectAllCookies = async () => {
    onBannerButtonClick();
    setShowFloatingLogo(true);
    setIsVisible(false);
    setOpenCookieWallBanner(false);

    // Build per-category boolean map: necessary=true, others=false
    const rejectAllCategoryConsents: { [categoryId: number]: boolean } = {};
    cookieUserData?.category_consent_record?.forEach((c) => {
      rejectAllCategoryConsents[c.category_id] = !!c.category_necessary;
    });

    // 🚫 Immediately lock down future loads
    (window as any).__gotrustShim?.revokeAll();
    // optional: also explicitly set the map (keeps shim’s localStorage coherent)
    pushConsentToShim(rejectAllCategoryConsents);
    (window as any).__gotrustShim?.flushAllowed();

    // (optional) specifically nuke GA too
    purgeGoogleAnalyticsCookies();

    // Purge cookies belonging to now-denied categories
    purgeCookiesForDeniedCategories(rejectAllCategoryConsents, cookieUserData);

    // Make sure device info is collected
    const deviceData = deviceInfo || collectDeviceInfo();

    const responseBody: ResponseBody = {
      domain_id: domainId as number,
      subject_identity: subjectIdentity,
      geolocation: `${ip}(${countryCode})`,
      continent,
      country: countryName,
      source: 'web',
      cookie_category_consent: [],
      device_info: {
        browser: {
          name: deviceData.browserName,
          version: deviceData.browserVersion,
          user_agent: deviceData.userAgent,
        },
        operating_system: {
          name: deviceData.osName,
          version: deviceData.osVersion,
        },
        device: {
          type: deviceData.deviceType,
          is_mobile: deviceData.isMobile,
          is_tablet: deviceData.isTablet,
          is_desktop: deviceData.isDesktop,
          vendor: deviceData.mobileVendor,
          model: deviceData.mobileModel,
        },
        screen: {
          width: deviceData.screenWidth,
          height: deviceData.screenHeight,
          viewport_width: deviceData.viewportWidth,
          viewport_height: deviceData.viewportHeight,
          device_pixel_ratio: deviceData.devicePixelRatio,
        },
      },
    };

    const cookieConsentArray: CookieConsent[] =
      cookieUserData?.category_consent_record?.flatMap((category) => {
        if (category?.category_necessary) {
          const serviceCookies =
            category.services.flatMap((service) =>
              addCookiesToConsentArray(
                service.cookies || [],
                category.category_id,
                true,
                service.service_id
              )
            ) || [];
          const independentCookies = addCookiesToConsentArray(
            category.independent_cookies || [],
            category.category_id,
            true
          );
          return [...serviceCookies, ...independentCookies];
        } else if (!category?.category_necessary) {
          const serviceCookies =
            category.services.flatMap((service) =>
              addCookiesToConsentArray(
                service.cookies || [],
                category.category_id,
                false,
                service.service_id
              )
            ) || [];
          const independentCookies = addCookiesToConsentArray(
            category.independent_cookies || [],
            category.category_id,
            false
          );
          return [...serviceCookies, ...independentCookies];
        }
        return [];
      }) || [];

    responseBody.cookie_category_consent = cookieConsentArray;

    try {
      await axios.put(`${baseURL}/ucm/banner/record-status-update`, responseBody);
      // Get only necessary cookie IDs for "Reject All"
      const necessaryCookieIds: string[] = [];
      cookieUserData?.category_consent_record?.forEach((category) => {
        if (category.category_necessary) {
          category.services.forEach((service) => {
            service.cookies.forEach((cookie) => {
              necessaryCookieIds.push(cookie.cookie_id.toString());
            });
          });
          category.independent_cookies.forEach((cookie) => {
            necessaryCookieIds.push(cookie.cookie_id.toString());
          });
        }
      });

      // Get all available cookies for new cookie detection
      const allAvailableCookies: string[] = [];
      cookieUserData?.category_consent_record?.forEach((category) => {
        category.services.forEach((service) => {
          service.cookies.forEach((cookie) => {
            allAvailableCookies.push(cookie.cookie_id.toString());
          });
        });
        category.independent_cookies.forEach((cookie) => {
          allAvailableCookies.push(cookie.cookie_id.toString());
        });
      });

      const newUser: { [id: number]: boolean } = {};
      const newCat: { [id: number]: boolean } = {};
      cookieUserData?.category_consent_record?.forEach((c) => {
        const v = !!c.category_necessary;
        newCat[c.category_id] = v;
        c.services.forEach((s) => s.cookies.forEach((k) => (newUser[k.cookie_id] = v)));
        c.independent_cookies.forEach((k) => (newUser[k.cookie_id] = v));
      });
      setUserConsent(newUser);
      setCategoryConsent(newCat);

      // ✅ NEW: persist cookie with category_choices so shim enforces next visit
      persistConsentCookie(
        { subjectIdentity, domainId: domainId as number, domainURL, cookieUserData },
        {
          consentedCookieIds: necessaryCookieIds,
          allAvailableCookieIds: allAvailableCookies,
          consentsByCategory: rejectAllCategoryConsents,
        }
      );
      // Update local state to reflect consent choices (won't trigger new cookie detection)
      updateLocalConsentState(cookieConsentArray);
      setUserConsentCookies(cookieConsentArray);

      // Update GTM consent
      try {
        if (gtmManager && cookieUserData?.banner_configuration?.gtmConfiguration?.enabled) {
          const categoryConsents = cookieUserData?.category_consent_record?.reduce(
            (acc, category) => {
              if (category && typeof category.category_id === 'number') {
                // Only necessary cookies are granted in "Reject All"
                acc[category.category_id] = !!category.category_necessary;
              }
              return acc;
            },
            {} as { [categoryId: number]: boolean }
          );

          if (categoryConsents && Object.keys(categoryConsents).length > 0) {
            gtmManager.updateConsent(categoryConsents);
          }
        }
      } catch (error) {
        console.error('Error updating GTM consent in reject all flow:', error);
      }

      // Update Adobe Launch consent
      try {
        if (
          adobeLaunchManager &&
          cookieUserData?.banner_configuration?.adobeLaunchConfiguration?.enabled
        ) {
          const categoryConsents = cookieUserData?.category_consent_record?.reduce(
            (acc, category) => {
              if (category && typeof category.category_id === 'number') {
                // Only necessary cookies are granted in "Reject All"
                acc[category.category_id] = !!category.category_necessary;
              }
              return acc;
            },
            {} as { [categoryId: number]: boolean }
          );

          if (categoryConsents && Object.keys(categoryConsents).length > 0) {
            adobeLaunchManager.updateConsent(categoryConsents);
          }
        }
      } catch (error) {
        console.error('Error updating Adobe Launch consent in reject all flow:', error);
      }

      // Update Cookie Blocking Manager consent
      try {
        if (cookieBlockingManager) {
          const consentState: ConsentState = {};
          const cookieConsentState: CookieConsentState = {};
          cookieUserData?.category_consent_record.forEach((c) => {
            consentState[c.category_id] = !!c.category_necessary;
            c.services.forEach((s) =>
              s.cookies.forEach((k) => (cookieConsentState[k.cookie_id] = !!c.category_necessary))
            );
            c.independent_cookies.forEach(
              (k) => (cookieConsentState[k.cookie_id] = !!c.category_necessary)
            );
          });
          cookieBlockingManager.updateConsent(consentState);
          cookieBlockingManager.updateCookieConsent(cookieConsentState);

          // 🔄 COORDINATION: Sync with shim
          if ((window as any)?.__gotrustShim) {
            const shimConsent = {
              necessary: true,
              analytics: getConsentBySlug(consentState, 'analytics', cookieUserData),
              marketing: getConsentBySlug(consentState, 'marketing', cookieUserData),
              functional: getConsentBySlug(consentState, 'functional', cookieUserData),
              performance: getConsentBySlug(consentState, 'performance', cookieUserData),
            };
            (window as any)?.__gotrustShim?.updateConsent(shimConsent);
          }
        }
      } catch (error) {
        console.error('Error updating cookie blocking manager consent in reject all flow:', error);
      }
    } catch (error) {
      if (axios.isAxiosError(error)) {
        console.error(
          `Error Rejecting all Cookies: ${error.response?.status} - ${error.response?.statusText}`
        );
      } else {
        console?.error('An unexpected error occurred.');
      }
    }
  };

  //? Allow All
  const handleAcceptAllCookies = async () => {
    onBannerButtonClick();
    setShowFloatingLogo(true);
    setIsVisible(false);
    setOpenCookieWallBanner(false);

    // 1) Build map: every category = true
    const acceptAllCategoryConsents: { [categoryId: number]: boolean } = {};
    cookieUserData?.category_consent_record?.forEach((c) => {
      acceptAllCategoryConsents[c.category_id] = true;
    });

    // ✅ PUT THIS HERE (replace pushConsentToShim(...))
    (window as any).__gotrustShim?.updateConsent({
      necessary: true,
      analytics: true,
      marketing: true,
      functional: true,
      performance: true,
    });
    (window as any).__gotrustShim?.flushAllowed();

    // Make sure device info is collected
    const deviceData = deviceInfo || collectDeviceInfo();

    const responseBody: ResponseBody = {
      domain_id: domainId as number,
      subject_identity: subjectIdentity,
      geolocation: `${ip}(${countryCode})`,
      continent,
      source: 'web',
      country: countryName,
      cookie_category_consent: [],
      device_info: {
        browser: {
          name: deviceData.browserName,
          version: deviceData.browserVersion,
          user_agent: deviceData.userAgent,
        },
        operating_system: {
          name: deviceData.osName,
          version: deviceData.osVersion,
        },
        device: {
          type: deviceData.deviceType,
          is_mobile: deviceData.isMobile,
          is_tablet: deviceData.isTablet,
          is_desktop: deviceData.isDesktop,
          vendor: deviceData.mobileVendor,
          model: deviceData.mobileModel,
        },
        screen: {
          width: deviceData.screenWidth,
          height: deviceData.screenHeight,
          viewport_width: deviceData.viewportWidth,
          viewport_height: deviceData.viewportHeight,
          device_pixel_ratio: deviceData.devicePixelRatio,
        },
      },
    };

    const cookieConsentArray: CookieConsent[] =
      cookieUserData?.category_consent_record?.flatMap((category) => {
        const serviceCookies =
          category.services.flatMap((service) =>
            addCookiesToConsentArray(
              service.cookies || [],
              category.category_id,
              true,
              service.service_id
            )
          ) || [];
        const independentCookies = addCookiesToConsentArray(
          category.independent_cookies || [],
          category.category_id,
          true
        );
        return [...serviceCookies, ...independentCookies];
      }) || [];

    responseBody.cookie_category_consent = cookieConsentArray;

    try {
      await axios.put(`${baseURL}/ucm/banner/record-status-update`, responseBody);
      // Get all cookie IDs for "Allow All"
      const allCookieIds: string[] = [];
      cookieUserData?.category_consent_record?.forEach((category) => {
        category.services.forEach((service) => {
          service.cookies.forEach((cookie) => {
            allCookieIds.push(cookie.cookie_id.toString());
          });
        });
        category.independent_cookies.forEach((cookie) => {
          allCookieIds.push(cookie.cookie_id.toString());
        });
      });

      const newUser: { [id: number]: boolean } = {};
      const newCat: { [id: number]: boolean } = {};
      cookieUserData?.category_consent_record?.forEach((c) => {
        newCat[c.category_id] = true;
        c.services.forEach((s) => s.cookies.forEach((k) => (newUser[k.cookie_id] = true)));
        c.independent_cookies.forEach((k) => (newUser[k.cookie_id] = true));
      });
      setUserConsent(newUser);
      setCategoryConsent(newCat);

      persistConsentCookie(
        { subjectIdentity, domainId: domainId as number, domainURL, cookieUserData },
        {
          consentedCookieIds: allCookieIds,
          allAvailableCookieIds: allCookieIds,
          consentsByCategory: acceptAllCategoryConsents,
        }
      );
      // Update local state to reflect consent choices (won't trigger new cookie detection)
      updateLocalConsentState(cookieConsentArray);
      setUserConsentCookies(cookieConsentArray);

      // Update GTM consent
      try {
        if (gtmManager && cookieUserData?.banner_configuration?.gtmConfiguration?.enabled) {
          const categoryConsents = cookieUserData.category_consent_record.reduce(
            (acc, category) => {
              if (category && typeof category.category_id === 'number') {
                acc[category.category_id] = true; // All consents are granted in "Accept All"
              }
              return acc;
            },
            {} as { [categoryId: number]: boolean }
          );

          if (categoryConsents && Object.keys(categoryConsents).length > 0) {
            gtmManager.updateConsent(categoryConsents);
          }
        }
      } catch (error) {
        console.error('Error updating GTM consent in accept all flow:', error);
      }

      // Update Adobe Launch consent
      try {
        if (
          adobeLaunchManager &&
          cookieUserData?.banner_configuration?.adobeLaunchConfiguration?.enabled
        ) {
          const categoryConsents = cookieUserData.category_consent_record.reduce(
            (acc, category) => {
              if (category && typeof category.category_id === 'number') {
                acc[category.category_id] = true; // All consents are granted in "Accept All"
              }
              return acc;
            },
            {} as { [categoryId: number]: boolean }
          );

          if (categoryConsents && Object.keys(categoryConsents).length > 0) {
            adobeLaunchManager.updateConsent(categoryConsents);
          }
        }
      } catch (error) {
        console.error('Error updating Adobe Launch consent in accept all flow:', error);
      }

      // Update Cookie Blocking Manager consent
      try {
        if (cookieBlockingManager) {
          const consentState: ConsentState = {};
          const cookieConsentState: CookieConsentState = {};
          cookieUserData?.category_consent_record?.forEach((c) => {
            consentState[c.category_id] = true;
            c.services.forEach((s) =>
              s.cookies.forEach((k) => (cookieConsentState[k.cookie_id] = true))
            );
            c.independent_cookies.forEach((k) => (cookieConsentState[k.cookie_id] = true));
          });
          cookieBlockingManager.updateConsent(consentState);
          cookieBlockingManager.updateCookieConsent(cookieConsentState);

          // 🔄 COORDINATION: Sync with shim
          if ((window as any).__gotrustShim) {
            const shimConsent = {
              necessary: true,
              analytics: true,
              marketing: true,
              functional: true,
              performance: true,
            };
            (window as any).__gotrustShim.updateConsent(shimConsent);
            (window as any).__gotrustShim.flushAllowed(); // Execute queued scripts
          }
        }

        const categoryConsents =
          cookieUserData?.category_consent_record?.reduce(
            (acc, c) => {
              acc[c.category_id] = true;
              return acc;
            },
            {} as { [categoryId: number]: boolean }
          ) || {};

        // ✅ Now load vendors after we’ve updated consent
        loadVendorsAfterConsent(categoryConsents);
      } catch (error) {
        console.error('Error updating cookie blocking manager consent in accept all flow:', error);
      }
    } catch (error) {
      if (axios.isAxiosError(error)) {
        console.error(
          `Error Accepting all Cookies: ${error.response?.status} - ${error.response?.statusText}`
        );
      } else {
        console.error('An unexpected error occurred.');
      }
    }
  };

  //? Allow Selected
  const handleAllowSelection = async () => {
    onBannerButtonClick();
    if (selectedNavItem !== 2) {
      setOpenCookieWallBanner(true);
      setSelectedNavItem(2);
      handleNavbar(2);
      return;
    }

    setShowFloatingLogo(true);
    setIsVisible(false);
    setOpenCookieWallBanner(false);
    // Make sure device info is collected
    const deviceData = deviceInfo || collectDeviceInfo();

    const responseBody: ResponseBody = {
      domain_id: domainId as number,
      subject_identity: subjectIdentity,
      geolocation: `${ip}(${countryCode})`,
      continent,
      country: countryName,
      source: 'web',
      cookie_category_consent: [],
      device_info: {
        browser: {
          name: deviceData.browserName,
          version: deviceData.browserVersion,
          user_agent: deviceData.userAgent,
        },
        operating_system: {
          name: deviceData.osName,
          version: deviceData.osVersion,
        },
        device: {
          type: deviceData.deviceType,
          is_mobile: deviceData.isMobile,
          is_tablet: deviceData.isTablet,
          is_desktop: deviceData.isDesktop,
          vendor: deviceData.mobileVendor,
          model: deviceData.mobileModel,
        },
        screen: {
          width: deviceData.screenWidth,
          height: deviceData.screenHeight,
          viewport_width: deviceData.viewportWidth,
          viewport_height: deviceData.viewportHeight,
          device_pixel_ratio: deviceData.devicePixelRatio,
        },
      },
    };

    const cookieConsentArray: CookieConsent[] =
      cookieUserData?.category_consent_record?.flatMap((category) => {
        const serviceCookies: CookieConsent[] = category.services.flatMap((service) =>
          service.cookies.map((cookie) => ({
            category_id: category.category_id,
            consent_record_id: cookie.consent_record_id,
            consent_status: Object.prototype.hasOwnProperty.call(userConsent, cookie.cookie_id)
              ? userConsent[cookie.cookie_id]
              : cookie.consent,
            cookie_id: cookie.cookie_id,
            service_id: service.service_id,
          }))
        );
        const independentCookies: CookieConsent[] = category.independent_cookies.map((cookie) => ({
          category_id: category.category_id,
          consent_record_id: cookie.consent_record_id,
          consent_status: Object.prototype.hasOwnProperty.call(userConsent, cookie.cookie_id)
            ? userConsent[cookie.cookie_id]
            : cookie.consent,
          cookie_id: cookie.cookie_id,
        }));
        return [...serviceCookies, ...independentCookies];
      }) || [];

    responseBody.cookie_category_consent = cookieConsentArray;

    try {
      await axios.put(`${baseURL}/ucm/banner/record-status-update`, responseBody);

      // Build consented cookie IDs array properly (same approach as other functions)
      const consentedCookieIds: string[] = [];
      cookieUserData?.category_consent_record?.forEach((category) => {
        // Always include necessary cookies
        if (category.category_necessary) {
          category.services.forEach((service) => {
            service.cookies.forEach((cookie) => {
              consentedCookieIds.push(cookie.cookie_id.toString());
            });
          });
          category.independent_cookies.forEach((cookie) => {
            consentedCookieIds.push(cookie.cookie_id.toString());
          });
        } else {
          // For non-necessary cookies, check user consent
          category.services.forEach((service) => {
            service.cookies.forEach((cookie) => {
              if (userConsent[cookie.cookie_id] === true) {
                consentedCookieIds.push(cookie.cookie_id.toString());
              }
            });
          });
          category.independent_cookies.forEach((cookie) => {
            if (userConsent[cookie.cookie_id] === true) {
              consentedCookieIds.push(cookie.cookie_id.toString());
            }
          });
        }
      });

      // Get all available cookies for new cookie detection
      const allAvailableCookies: string[] = [];
      cookieUserData?.category_consent_record?.forEach((category) => {
        category.services.forEach((service) => {
          service.cookies.forEach((cookie) => {
            allAvailableCookies.push(cookie.cookie_id.toString());
          });
        });
        category.independent_cookies.forEach((cookie) => {
          allAvailableCookies.push(cookie.cookie_id.toString());
        });
      });

      // Always update the gotrust_pb_ydt cookie with latest consent information
      const categoryConsents =
        cookieUserData?.category_consent_record?.reduce(
          (acc, category) => {
            if (category.category_necessary) {
              acc[category.category_id] = true;
            } else {
              const hasServiceCookieConsent =
                category.services?.some((s) =>
                  s.cookies?.some((k) => userConsent[k.cookie_id] === true)
                ) ?? false;
              const hasIndependentCookieConsent =
                category.independent_cookies?.some((k) => userConsent[k.cookie_id] === true) ??
                false;
              acc[category.category_id] = hasServiceCookieConsent || hasIndependentCookieConsent;
            }
            return acc;
          },
          {} as { [categoryId: number]: boolean }
        ) || {};

      // keep the user’s per-cookie choices, but force necessary cookies to true
      const forcedUser = { ...userConsent };
      cookieUserData?.category_consent_record?.forEach((c) => {
        if (c.category_necessary) {
          c.services.forEach((s) => s.cookies.forEach((k) => (forcedUser[k.cookie_id] = true)));
          c.independent_cookies.forEach((k) => (forcedUser[k.cookie_id] = true));
        }
      });
      setUserConsent(forcedUser);
      setCategoryConsent(categoryConsents);

      // back to normal state
      setOpenCookieWallBanner(false);
      setSelectedNavItem(1);
      handleNavbar(1);

      // 1) ✅ Tell the shim first so it can unblock the right things immediately
      pushConsentToShim(categoryConsents);
      (window as any).__gotrustShim?.flushAllowed();

      // Purge only those categories the user left OFF
      purgeCookiesForDeniedCategories(categoryConsents, cookieUserData);

      // (optional) if analytics is off, make sure GA cookies are removed
      if (!getConsentBySlug(categoryConsents, 'analytics', cookieUserData)) {
        purgeGoogleAnalyticsCookies();
      }

      // 2) ✅ Persist cookie with category_choices for next visit
      persistConsentCookie(
        { subjectIdentity, domainId: domainId as number, domainURL, cookieUserData },
        {
          consentedCookieIds, // you computed above
          allAvailableCookieIds: allAvailableCookies, // you computed above
          consentsByCategory: categoryConsents,
        }
      );

      // Update local state to reflect consent choices (won't trigger new cookie detection)
      updateLocalConsentState(cookieConsentArray);
      setUserConsentCookies(cookieConsentArray);

      // Update GTM consent
      try {
        if (gtmManager && cookieUserData?.banner_configuration?.gtmConfiguration?.enabled) {
          // Create a map of category consents based on user selections
          const categoryConsents = cookieUserData.category_consent_record.reduce(
            (acc, category) => {
              if (!category || typeof category.category_id !== 'number') {
                return acc;
              }

              // For necessary categories, always grant consent
              if (category.category_necessary) {
                acc[category.category_id] = true;
                return acc;
              }

              try {
                // For other categories, check if any cookie in the category has consent
                const hasServiceCookieConsent =
                  Array.isArray(category.services) &&
                  category.services.some(
                    (service) =>
                      Array.isArray(service?.cookies) &&
                      service.cookies.some(
                        (cookie) =>
                          cookie && cookie.cookie_id && userConsent[cookie.cookie_id] === true
                      )
                  );

                const hasIndependentCookieConsent =
                  Array.isArray(category.independent_cookies) &&
                  category.independent_cookies.some(
                    (cookie) => cookie && cookie.cookie_id && userConsent[cookie.cookie_id] === true
                  );

                acc[category.category_id] = hasServiceCookieConsent || hasIndependentCookieConsent;
              } catch (innerError) {
                console.error('Error processing category consent:', innerError);
                // Default to false if there's an error
                acc[category.category_id] = false;
              }

              return acc;
            },
            {} as { [categoryId: number]: boolean }
          );

          if (categoryConsents && Object.keys(categoryConsents).length > 0) {
            gtmManager.updateConsent(categoryConsents);
          }
        }
      } catch (error) {
        console.error('Error updating GTM consent in allow selection flow:', error);
      }

      // Update Adobe Launch consent
      try {
        if (
          adobeLaunchManager &&
          cookieUserData?.banner_configuration?.adobeLaunchConfiguration?.enabled
        ) {
          // Create a map of category consents based on user selections
          const categoryConsents = cookieUserData.category_consent_record.reduce(
            (acc, category) => {
              if (!category || typeof category.category_id !== 'number') {
                return acc;
              }

              // For necessary categories, always grant consent
              if (category.category_necessary) {
                acc[category.category_id] = true;
                return acc;
              }

              try {
                // For other categories, check if any cookie in the category has consent
                const hasServiceCookieConsent =
                  Array.isArray(category.services) &&
                  category.services.some(
                    (service) =>
                      Array.isArray(service?.cookies) &&
                      service.cookies.some(
                        (cookie) =>
                          cookie && cookie.cookie_id && userConsent[cookie.cookie_id] === true
                      )
                  );

                const hasIndependentCookieConsent =
                  Array.isArray(category.independent_cookies) &&
                  category.independent_cookies.some(
                    (cookie) => cookie && cookie.cookie_id && userConsent[cookie.cookie_id] === true
                  );

                acc[category.category_id] = hasServiceCookieConsent || hasIndependentCookieConsent;
              } catch (innerError) {
                console.error('Error processing category consent for Adobe Launch:', innerError);
                // Default to false if there's an error
                acc[category.category_id] = false;
              }

              return acc;
            },
            {} as { [categoryId: number]: boolean }
          );

          if (categoryConsents && Object.keys(categoryConsents).length > 0) {
            adobeLaunchManager.updateConsent(categoryConsents);
          }
        }
      } catch (error) {
        console.error('Error updating Adobe Launch consent in allow selection flow:', error);
      }

      // Update Cookie Blocking Manager consent
      try {
        if (cookieBlockingManager) {
          const consentState: ConsentState = {};
          const cookieConsentState: CookieConsentState = {};
          cookieUserData?.category_consent_record?.forEach((c) => {
            if (c.category_necessary) {
              consentState[c.category_id] = true;
              c.services.forEach((s) =>
                s.cookies.forEach((k) => (cookieConsentState[k.cookie_id] = true))
              );
              c.independent_cookies.forEach((k) => (cookieConsentState[k.cookie_id] = true));
            } else {
              c.services.forEach((s) =>
                s.cookies.forEach(
                  (k) => (cookieConsentState[k.cookie_id] = userConsent[k.cookie_id] === true)
                )
              );
              c.independent_cookies.forEach(
                (k) => (cookieConsentState[k.cookie_id] = userConsent[k.cookie_id] === true)
              );
              consentState[c.category_id] =
                c.services.some((s) => s.cookies.some((k) => userConsent[k.cookie_id] === true)) ||
                c.independent_cookies.some((k) => userConsent[k.cookie_id] === true);
            }
          });
          cookieBlockingManager.updateConsent(consentState);
          cookieBlockingManager.updateCookieConsent(cookieConsentState);

          // 🔄 COORDINATION: Sync with shim
          if ((window as any).__gotrustShim) {
            const shimConsent = {
              necessary: true,
              analytics: getConsentBySlug(consentState, 'analytics', cookieUserData),
              marketing: getConsentBySlug(consentState, 'marketing', cookieUserData),
              functional: getConsentBySlug(consentState, 'functional', cookieUserData),
              performance: getConsentBySlug(consentState, 'performance', cookieUserData),
            };
            (window as any).__gotrustShim.updateConsent(shimConsent);
            (window as any).__gotrustShim.flushAllowed(); // Execute queued scripts
          }
        }

        const categoryConsents =
          cookieUserData?.category_consent_record?.reduce(
            (acc, c) => {
              if (c.category_necessary) {
                acc[c.category_id] = true;
              } else {
                const hasServiceCookieConsent =
                  c.services?.some((s) =>
                    s.cookies?.some((k) => userConsent[k.cookie_id] === true)
                  ) ?? false;
                const hasIndependentCookieConsent =
                  c.independent_cookies?.some((k) => userConsent[k.cookie_id] === true) ?? false;
                acc[c.category_id] = hasServiceCookieConsent || hasIndependentCookieConsent;
              }
              return acc;
            },
            {} as { [categoryId: number]: boolean }
          ) || {};

        // ✅ Load vendors only if any non-necessary consent is now granted
        loadVendorsAfterConsent(categoryConsents);
      } catch (error) {
        console.error(
          'Error updating cookie blocking manager consent in allow selection flow:',
          error
        );
      }
    } catch (error) {
      if (axios.isAxiosError(error)) {
        console.error(
          `Error Updating Cookie Preferences data: ${error.response?.status} - ${error.response?.statusText}`
        );
      } else {
        console.error('An unexpected error occurred.');
      }
    }
  };

  const ctas: Array<{
    key: 'deny' | 'allowSelection' | 'allowAll';
    label: string;
    onClick: () => void;
  }> = [];

  // Get button order from configuration, default to original order if not specified
  const buttonOrder = cookieUserData?.banner_configuration?.bannerDesign?.buttonOrder ?? [
    'deny',
    'allowSelection',
    'allowAll',
  ];

  // Build ctas array based on button order
  buttonOrder.forEach((buttonKey: 'deny' | 'allowSelection' | 'allowAll') => {
    if (buttonKey === 'deny' && buttonsCfg.deny) {
      ctas.push({
        key: 'deny',
        label:
          selectedLanguage === 'en'
            ? cookieUserData?.banner_configuration.bannerDesign.denyButtonLabel
            : (translatedData?.banner_configuration?.bannerDesign.denyButtonLabel ?? ''),
        onClick: handleRejectAllCookies,
      });
    } else if (buttonKey === 'allowSelection' && buttonsCfg.allowSelection) {
      ctas.push({
        key: 'allowSelection',
        label:
          openCookieWallBanner &&
          cookieUserData?.banner_configuration?.bannerDesign?.layoutType === 'footer'
            ? selectedLanguage === 'en'
              ? cookieUserData?.banner_configuration.bannerDesign.saveChoicesButtonLabel
              : (translatedData?.banner_configuration?.bannerDesign.saveChoicesButtonLabel ?? '')
            : selectedLanguage === 'en'
              ? cookieUserData?.banner_configuration.bannerDesign.allowSelectionButtonLabel
              : (translatedData?.banner_configuration?.bannerDesign.allowSelectionButtonLabel ??
                ''),
        onClick: handleAllowSelection,
      });
    } else if (buttonKey === 'allowAll' && buttonsCfg.allowAll) {
      ctas.push({
        key: 'allowAll',
        label:
          selectedLanguage === 'en'
            ? cookieUserData?.banner_configuration.bannerDesign.allowAllButtonLabel
            : (translatedData?.banner_configuration?.bannerDesign.allowAllButtonLabel ?? ''),
        onClick: handleAcceptAllCookies,
      });
    }
  });

  // Build preference modal ctas array (for footer layout dialog)
  const preferenceModalCtas: Array<{
    key: 'deny' | 'allowSelection' | 'allowAll';
    label: string;
    onClick: () => void;
  }> = [];

  const isFooterLayoutDialog =
    openCookieWallBanner &&
    cookieUserData?.banner_configuration?.bannerDesign?.layoutType === 'footer';

  if (isFooterLayoutDialog) {
    const preferenceModalButtonsCfg =
      cookieUserData?.banner_configuration?.bannerDesign?.preferenceModalButtons ?? buttonsCfg;
    const preferenceModalButtonOrder =
      cookieUserData?.banner_configuration?.bannerDesign?.preferenceModalButtonOrder ?? buttonOrder;

    preferenceModalButtonOrder.forEach((buttonKey: 'deny' | 'allowSelection' | 'allowAll') => {
      if (buttonKey === 'deny' && preferenceModalButtonsCfg.deny) {
        preferenceModalCtas.push({
          key: 'deny',
          label:
            selectedLanguage === 'en'
              ? (cookieUserData?.banner_configuration.bannerDesign.preferenceModalDenyButtonLabel ??
                cookieUserData?.banner_configuration.bannerDesign.denyButtonLabel)
              : (translatedData?.banner_configuration?.bannerDesign
                  .preferenceModalDenyButtonLabel ??
                translatedData?.banner_configuration?.bannerDesign.denyButtonLabel ??
                ''),
          onClick: handleRejectAllCookies,
        });
      } else if (buttonKey === 'allowSelection' && preferenceModalButtonsCfg.allowSelection) {
        preferenceModalCtas.push({
          key: 'allowSelection',
          label:
            selectedLanguage === 'en'
              ? (cookieUserData?.banner_configuration.bannerDesign
                  .preferenceModalSaveChoicesButtonLabel ?? 'Save My Choices')
              : (translatedData?.banner_configuration?.bannerDesign
                  .preferenceModalSaveChoicesButtonLabel ?? 'Save My Choices'),
          onClick: handleAllowSelection,
        });
      } else if (buttonKey === 'allowAll' && preferenceModalButtonsCfg.allowAll) {
        preferenceModalCtas.push({
          key: 'allowAll',
          label:
            selectedLanguage === 'en'
              ? (cookieUserData?.banner_configuration.bannerDesign
                  .preferenceModalAllowAllButtonLabel ??
                cookieUserData?.banner_configuration.bannerDesign.allowAllButtonLabel)
              : (translatedData?.banner_configuration?.bannerDesign
                  .preferenceModalAllowAllButtonLabel ??
                translatedData?.banner_configuration?.bannerDesign.allowAllButtonLabel ??
                ''),
          onClick: handleAcceptAllCookies,
        });
      }
    });
  }

  // Render content based on the selected navigation tab
  const renderContent = () => {
    switch (selectedNavItem) {
      case 1:
        return cookieUserData ? (
          <div className={styles.cookieWallBannerContentConsent}>
            <div
              style={{
                fontWeight: '600',
                fontSize: isMobileDevice ? '16px' : (bannerStyles.fontSize ?? '16px'),
                fontFamily: bannerStyles.fontFamily ?? 'sans-serif',
                lineHeight: isMobileDevice ? '1.3' : '1.4',
              }}
            >
              {selectedLanguage === 'en'
                ? cookieUserData.banner_title
                : translatedData?.banner_title}
            </div>
            <div
              style={{
                fontSize: isMobileDevice ? '14px' : (bannerStyles.fontSize ?? '16px'),
                fontFamily: bannerStyles.fontFamily ?? 'sans-serif',
                lineHeight: isMobileDevice ? '1.4' : '1.5',
              }}
            >
              {selectedLanguage === 'en' ? (
                <div dangerouslySetInnerHTML={{ __html: cookieUserData.banner_description }} />
              ) : (
                <div
                  dangerouslySetInnerHTML={{ __html: translatedData?.banner_description || '' }}
                />
              )}
            </div>
          </div>
        ) : (
          <p
            style={{
              marginTop: '20px',
              display: 'flex',
              justifyContent: 'center',
              alignItems: 'center',
              fontSize: isMobileDevice ? '18px' : '24px',
              fontWeight: '600',
              fontFamily: bannerStyles.fontFamily ?? 'sans-serif',
            }}
          >
            No Consent to show
          </p>
        );
      case 2:
        const dataToRender = selectedLanguage === 'en' ? cookieUserData : translatedData;
        return dataToRender ? (
          <div className={styles.cookieWallBannerDetails}>
            <div className={styles.cookieWallBannerDetailsContent}>
              {/* Display details tab description if it exists and has content */}
              {selectedLanguage === 'en' &&
              cookieUserData?.banner_configuration?.bannerDesign?.detailsTabDescription &&
              cookieUserData.banner_configuration.bannerDesign.detailsTabDescription.trim() !==
                '' &&
              cookieUserData.banner_configuration.bannerDesign.detailsTabDescription !==
                '<p></p>' ? (
                <div
                  style={{
                    fontSize: isMobileDevice ? '13px' : (bannerStyles.fontSize ?? '16px'),
                    fontFamily: bannerStyles.fontFamily ?? 'sans-serif',
                    lineHeight: isMobileDevice ? '1.4' : '1.5',
                  }}
                  dangerouslySetInnerHTML={{
                    __html: cookieUserData.banner_configuration.bannerDesign.detailsTabDescription,
                  }}
                ></div>
              ) : (
                translatedData?.banner_configuration?.bannerDesign?.detailsTabDescription &&
                translatedData.banner_configuration.bannerDesign.detailsTabDescription.trim() !==
                  '' &&
                translatedData.banner_configuration.bannerDesign.detailsTabDescription !==
                  '<p></p>' && (
                  <div
                    style={{
                      fontSize: isMobileDevice ? '13px' : (bannerStyles.fontSize ?? '16px'),
                      fontFamily: bannerStyles.fontFamily ?? 'sans-serif',
                      lineHeight: isMobileDevice ? '1.4' : '1.5',
                    }}
                    dangerouslySetInnerHTML={{
                      __html:
                        translatedData.banner_configuration.bannerDesign.detailsTabDescription,
                    }}
                  ></div>
                )
              )}
              <Accordion>
                {dataToRender?.category_consent_record?.map(
                  (category: CategoryConsentRecordProperties) => (
                    <AccordionItem key={category.category_id.toString()}>
                      <AccordionTrigger>
                        <div className={styles.cookieWallBannerAccordionTrigger}>
                          <p
                            style={{
                              fontSize: isMobileDevice ? '14px' : (bannerStyles.fontSize ?? '16px'),
                              fontFamily: bannerStyles.fontFamily ?? 'sans-serif',
                            }}
                          >
                            {convertString(category.category_name)}
                          </p>
                          <BasicSwitch
                            id={category.category_id.toString()}
                            checked={categoryConsent[category.category_id] ?? false}
                            onClick={(event) => event.stopPropagation()}
                            onCheckedChange={(value: boolean) => {
                              handleCategoryConsentChange(category.category_id, value, category);
                            }}
                            disabled={category.category_necessary}
                            style={{
                              backgroundColor: categoryConsent[category.category_id]
                                ? buttonColor
                                : 'hsl(214, 31.8%, 91.4%)',
                            }}
                          />
                        </div>
                      </AccordionTrigger>
                      <AccordionContent>
                        <p
                          style={{
                            marginBottom: '8px',
                            fontSize: isMobileDevice ? '13px' : (bannerStyles.fontSize ?? '16px'),
                            fontFamily: bannerStyles.fontFamily ?? 'sans-serif',
                            lineHeight: isMobileDevice ? '1.4' : '1.5',
                          }}
                        >
                          {category.category_description}
                        </p>
                        {category.services.map((service: ServiceProperties) => (
                          <Accordion
                            key={service.service_id.toString()}
                            className={styles.cookieWallBannerServiceAccordion}
                          >
                            <AccordionItem key={service.service_id.toString()}>
                              <AccordionTrigger>
                                <div
                                  style={{
                                    fontSize: isMobileDevice
                                      ? '14px'
                                      : (bannerStyles.fontSize ?? '16px'),
                                    fontFamily: bannerStyles.fontFamily ?? 'sans-serif',
                                  }}
                                >
                                  {convertString(service.service_name)}
                                </div>
                              </AccordionTrigger>
                              <AccordionContent>
                                <p
                                  style={{
                                    marginBottom: '8px',
                                    fontSize: isMobileDevice
                                      ? '13px'
                                      : (bannerStyles.fontSize ?? '16px'),
                                    fontFamily: bannerStyles.fontFamily ?? 'sans-serif',
                                    lineHeight: isMobileDevice ? '1.4' : '1.5',
                                  }}
                                >
                                  {service.service_description}
                                </p>
                                <div className={styles.cookieWallBannerServiceSection}>
                                  {service.cookies.map((cookie: CookieProperties) => (
                                    <div
                                      key={cookie.cookie_id}
                                      className={styles.cookieWallBannerServiceContent}
                                    >
                                      <div
                                        style={{
                                          display: 'flex',
                                          justifyContent: 'space-between',
                                          alignItems: 'center',
                                          width: '100%',
                                          flexDirection: 'row',
                                        }}
                                      >
                                        <p
                                          style={{
                                            fontWeight: '600',
                                            fontSize: isMobileDevice
                                              ? '14px'
                                              : (bannerStyles.fontSize ?? '16px'),
                                            fontFamily: bannerStyles.fontFamily ?? 'sans-serif',
                                          }}
                                        >
                                          {cookie.cookie_key}
                                        </p>
                                        <BasicSwitch
                                          id={cookie.cookie_id.toString()}
                                          checked={userConsent[cookie.cookie_id] ?? false}
                                          onClick={(event) => event.stopPropagation()}
                                          onCheckedChange={(value: boolean) => {
                                            handleCookieConsentChange(cookie.cookie_id, value);
                                          }}
                                          disabled={category.category_necessary}
                                          style={{
                                            backgroundColor: userConsent[cookie.cookie_id]
                                              ? buttonColor
                                              : 'hsl(214.3 31.8% 91.4%)',
                                          }}
                                        />
                                      </div>
                                      <p
                                        style={{
                                          fontSize: isMobileDevice
                                            ? '13px'
                                            : (bannerStyles.fontSize ?? '16px'),
                                          fontFamily: bannerStyles.fontFamily ?? 'sans-serif',
                                          lineHeight: isMobileDevice ? '1.4' : '1.5',
                                        }}
                                      >
                                        {cookie.description}
                                      </p>
                                      <p>
                                        <span className={styles.cookieExpiration}>
                                          Cookie Expiration:
                                        </span>{' '}
                                        {cookie.expiration === 'Session' ||
                                        cookie.expiration === 'session'
                                          ? 'Session'
                                          : convertDateToHumanView(cookie.expiration)}
                                      </p>
                                    </div>
                                  ))}
                                </div>
                              </AccordionContent>
                            </AccordionItem>
                          </Accordion>
                        ))}
                        {/* <section className={styles.cookieWallBannerCategorySection}>
                          {category.independent_cookies.map((cookie: CookieProperties) => (
                            <div
                              key={cookie.cookie_id}
                              className={styles.cookieWallBannerCategoryContent}
                            >
                              <div
                                style={{
                                  display: 'flex',
                                  justifyContent: 'space-between',
                                  alignItems: 'center',
                                  width: '100%',
                                  flexDirection: 'row',
                                }}
                              >
                                <p
                                  style={{
                                    fontWeight: '600',
                                    fontSize: bannerStyles.fontSize ?? '16px',
                                    fontFamily: bannerStyles.fontFamily ?? 'sans-serif',
                                  }}
                                >
                                  {cookie.cookie_key}
                                </p>
                                <BasicSwitch
                                  id={cookie.cookie_id.toString()}
                                  checked={userConsent[cookie.cookie_id] ?? false}
                                  onClick={(event) => event.stopPropagation()}
                                  onCheckedChange={(value: boolean) => {
                                    handleCookieConsentChange(cookie.cookie_id, value);
                                  }}
                                  disabled={category.category_necessary}
                                  style={{
                                    backgroundColor: userConsent[cookie.cookie_id]
                                      ? buttonColor
                                      : 'hsl(214.3 31.8% 91.4%)',
                                  }}
                                />
                              </div>
                              <p
                                style={{
                                  fontSize: bannerStyles.fontSize ?? '16px',
                                  fontFamily: bannerStyles.fontFamily ?? 'sans-serif',
                                }}
                              >
                                {cookie.description}
                              </p>
                              <p>
                                <span className={styles.cookieExpiration}>Cookie Expiration:</span>{' '}
                                {formatExpiration(cookie.expiration)}
                              </p>
                            </div>
                          ))}
                        </section> */}
                      </AccordionContent>
                    </AccordionItem>
                  )
                )}
              </Accordion>
            </div>
          </div>
        ) : (
          <p className={styles.cookieWallBannerNoDetails}>No Details to show</p>
        );
      case 3:
        return cookieUserData?.banner_configuration?.bannerDesign?.aboutSectionContent &&
          selectedLanguage === 'en' ? (
          <div className={styles.cookieWallBannerAbout}>
            <div
              dangerouslySetInnerHTML={{
                __html: cookieUserData.banner_configuration.bannerDesign.aboutSectionContent,
              }}
            ></div>
            {(cookieUserData.banner_configuration.bannerDesign.cookiePolicyUrl ||
              cookieUserData.banner_configuration.bannerDesign.privacyPolicyUrl) && (
              <div
                style={{
                  display: 'flex',
                  width: '100%',
                  justifyContent: 'flex-start',
                  gap: '12px',
                }}
              >
                {cookieUserData.banner_configuration.bannerDesign.cookiePolicyUrl && (
                  <a
                    href={cookieUserData.banner_configuration.bannerDesign.cookiePolicyUrl}
                    target="_blank"
                    rel="noopener noreferrer"
                    style={{
                      display: 'inline-block',
                      textAlign: 'center',
                      textDecoration: 'underline',
                      color: cookieUserData.banner_configuration.bannerDesign.colorScheme,
                      fontSize: bannerStyles.fontSize ?? '16px',
                      border: 'none',
                      fontFamily: bannerStyles.fontFamily ?? 'sans-serif',
                    }}
                  >
                    Cookie Policy
                  </a>
                )}
                {cookieUserData.banner_configuration.bannerDesign.privacyPolicyUrl && (
                  <a
                    href={cookieUserData.banner_configuration.bannerDesign.privacyPolicyUrl}
                    target="_blank"
                    rel="noopener noreferrer"
                    style={{
                      display: 'inline-block',
                      textAlign: 'center',
                      textDecoration: 'underline',
                      color: cookieUserData.banner_configuration.bannerDesign.colorScheme,
                      fontSize: bannerStyles.fontSize ?? '16px',
                      border: 'none',
                      fontFamily: bannerStyles.fontFamily ?? 'sans-serif',
                    }}
                  >
                    Privacy Policy
                  </a>
                )}
              </div>
            )}
          </div>
        ) : translatedData?.banner_configuration?.bannerDesign?.aboutSectionContent &&
          selectedLanguage !== 'en' ? (
          <div className={styles.cookieWallBannerAbout}>
            <div
              dangerouslySetInnerHTML={{
                __html: translatedData.banner_configuration.bannerDesign.aboutSectionContent,
              }}
            ></div>
            {(translatedData.banner_configuration.bannerDesign.cookiePolicyUrl ||
              translatedData.banner_configuration.bannerDesign.privacyPolicyUrl) && (
              <div
                style={{
                  display: 'flex',
                  width: '100%',
                  justifyContent: 'flex-start',
                  gap: '12px',
                }}
              >
                {translatedData.banner_configuration.bannerDesign.cookiePolicyUrl && (
                  <a
                    href={translatedData.banner_configuration.bannerDesign.cookiePolicyUrl}
                    target="_blank"
                    rel="noopener noreferrer"
                    style={{
                      display: 'inline-block',
                      textAlign: 'center',
                      textDecoration: 'underline',
                      color: translatedData.banner_configuration.bannerDesign.colorScheme,
                      fontSize: bannerStyles.fontSize ?? '16px',
                      border: 'none',
                      fontFamily: bannerStyles.fontFamily ?? 'sans-serif',
                    }}
                  >
                    Cookie Policy
                  </a>
                )}
                {translatedData.banner_configuration.bannerDesign.privacyPolicyUrl && (
                  <a
                    href={translatedData.banner_configuration.bannerDesign.privacyPolicyUrl}
                    target="_blank"
                    rel="noopener noreferrer"
                    style={{
                      display: 'inline-block',
                      textAlign: 'center',
                      textDecoration: 'underline',
                      color: translatedData.banner_configuration.bannerDesign.colorScheme,
                      fontSize: bannerStyles.fontSize ?? '16px',
                      border: 'none',
                      fontFamily: bannerStyles.fontFamily ?? 'sans-serif',
                    }}
                  >
                    Privacy Policy
                  </a>
                )}
              </div>
            )}
          </div>
        ) : (
          <></>
        );

      default:
        return <></>;
    }
  };

  // Early return if no cookie user data
  if (!cookieUserData) {
    return null;
  }

  // Determine which banner type to show
  const shouldShowWallBanner =
    isVisible &&
    (openCookieWallBanner ||
      cookieUserData.banner_configuration?.bannerDesign?.layoutType === 'wall');
  const shouldShowFooterBanner =
    isVisible &&
    cookieUserData.banner_configuration?.bannerDesign?.layoutType === 'footer' &&
    !openCookieWallBanner;
  const shouldShowFloatingLogo = showFloatingLogo && !isVisible;

  // Render Wall Banner
  const renderWallBanner = () => (
    <div className={styles.cookieWallBanner}>
      {isLoadingTranslations && selectedLanguage !== 'en' ? (
        <WallBannerLoader />
      ) : (
        <div
          ref={wallRef}
          className={[
            styles.cookieWallBannerContainer,
            styles.isolated,
            wallReady ? styles.isReady : '',
            wallReady ? styles.animIn : '',
            styles.motionShadowLite,
          ].join(' ')}
          style={bannerStyles}
          onAnimationEnd={(e) => {
            // remove animation-only classes and heavy paint hints
            e.currentTarget.classList.remove(styles.animIn, styles.motionShadowLite);
          }}
        >
          {/* Cookie Banner Header */}
          <div className={styles.cookieWallBannerHeader}>
            {cookieUserData.banner_configuration.bannerDesign.logoUrl &&
              cookieUserData.banner_configuration.bannerDesign.showLogo === 'true' && (
                <img
                  ref={logoRef}
                  src={cookieUserData.banner_configuration.bannerDesign.logoUrl}
                  alt="Brand"
                  className={styles.cookieWallBannerHeaderLogo}
                  style={{
                    width:
                      cookieUserData.banner_configuration.bannerDesign?.logoSize?.width ?? '100px',
                    height:
                      cookieUserData.banner_configuration.bannerDesign?.logoSize?.height ?? '70px',
                  }}
                  decoding="async"
                  fetchPriority="low"
                />
              )}
            <div className={styles.cookieWallBannerHeaderRightSide}>
              <div className={styles.cookieWallBannerFooterPoweredByConfig}>
                <span className={styles.cookieWallBannerHeaderPoweredBy}>Powered by</span>
                <img
                  src={gotrustTitle}
                  alt="GoTrust"
                  className={styles.cookieWallBannerHeaderPoweredByLogo}
                />
              </div>
              <div className={styles.cookieWallBannerHeaderConfig}>
                {cookieUserData?.banner_configuration?.bannerDesign?.showLanguageDropdown ? (
                  <select
                    className={styles.cookieWallBannerLanguageSelector}
                    value={selectedLanguage}
                    onChange={(e) => setSelectedLanguage(e.target.value)}
                  >
                    {languages?.map((lang) => (
                      <option
                        value={lang?.language_code}
                        onClick={() => setSelectedLanguage(lang?.language_code)}
                        key={lang?.language_code}
                      >
                        {lang?.language ? lang?.language : lang?.language_code}
                      </option>
                    ))}
                  </select>
                ) : null}
                {(cookieUserData?.banner_configuration?.bannerDesign?.allowBannerClose ?? true) && (
                  <button
                    onClick={handleClose}
                    style={{
                      marginLeft: '8px',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      width: '24px',
                      height: '24px',
                      borderRadius: '50%',
                      border: 'none',
                      background: 'transparent',
                      cursor: 'pointer',
                      color: bannerStyles.color,
                      transition: 'background-color 0.2s',
                    }}
                    onMouseEnter={(e) =>
                      (e.currentTarget.style.backgroundColor = 'rgba(0,0,0,0.1)')
                    }
                    onMouseLeave={(e) => (e.currentTarget.style.backgroundColor = 'transparent')}
                    aria-label="Close banner"
                  >
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      width="16"
                      height="16"
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="#4B5563"
                      strokeWidth="4"
                      strokeLinecap="round"
                      strokeLinejoin="round"
                    >
                      <line x1="18" y1="6" x2="6" y2="18"></line>
                      <line x1="6" y1="6" x2="18" y2="18"></line>
                    </svg>
                  </button>
                )}
              </div>
            </div>
          </div>

          {/* Cookie Banner Navbar */}
          <div className={styles.cookieWallBannerNavbar}>
            <button
              className={styles.cookieWallBannerNavbarTab}
              style={
                selectedNavItem === 1
                  ? {
                      color: buttonColor,
                      borderBottom: `2px solid ${buttonColor}`,
                      fontSize: isMobileDevice ? '14px' : (bannerStyles.fontSize ?? '16px'),
                      fontWeight: '600',
                      fontFamily: bannerStyles.fontFamily ?? 'sans-serif',
                    }
                  : {
                      color: '#414141',
                      fontSize: isMobileDevice ? '14px' : (bannerStyles.fontSize ?? '16px'),
                      fontWeight: '600',
                      fontFamily: bannerStyles.fontFamily ?? 'sans-serif',
                    }
              }
              onClick={() => handleNavbar(1)}
              onMouseEnter={(e) => (e.currentTarget.style.color = buttonColor)}
              onMouseLeave={(e) => {
                e.currentTarget.style.color = selectedNavItem === 1 ? buttonColor : '#414141';
              }}
            >
              {selectedLanguage === 'en'
                ? cookieUserData.banner_configuration.bannerDesign.consentTabHeading
                : translatedData?.banner_configuration?.bannerDesign.consentTabHeading || 'Consent'}
            </button>
            <button
              className={styles.cookieWallBannerNavbarTab}
              style={
                selectedNavItem === 2
                  ? {
                      color: buttonColor,
                      borderBottom: `2px solid ${buttonColor}`,
                      fontSize: isMobileDevice ? '14px' : (bannerStyles.fontSize ?? '16px'),
                      fontWeight: '600',
                      fontFamily: bannerStyles.fontFamily ?? 'sans-serif',
                    }
                  : {
                      color: '#414141',
                      fontSize: isMobileDevice ? '14px' : (bannerStyles.fontSize ?? '16px'),
                      fontWeight: '600',
                      fontFamily: bannerStyles.fontFamily ?? 'sans-serif',
                    }
              }
              onClick={() => handleNavbar(2)}
              onMouseEnter={(e) => (e.currentTarget.style.color = buttonColor)}
              onMouseLeave={(e) => {
                e.currentTarget.style.color = selectedNavItem === 2 ? buttonColor : '#414141';
              }}
            >
              {selectedLanguage === 'en'
                ? cookieUserData.banner_configuration.bannerDesign.detailsTabHeading
                : translatedData?.banner_configuration?.bannerDesign.detailsTabHeading || 'Details'}
            </button>
            <button
              className={styles.cookieWallBannerNavbarTab}
              style={
                selectedNavItem === 3
                  ? {
                      color: buttonColor,
                      borderBottom: `2px solid ${buttonColor}`,
                      fontSize: isMobileDevice ? '14px' : (bannerStyles.fontSize ?? '16px'),
                      fontWeight: '600',
                      fontFamily: bannerStyles.fontFamily ?? 'sans-serif',
                    }
                  : {
                      color: '#414141',
                      fontSize: isMobileDevice ? '14px' : (bannerStyles.fontSize ?? '16px'),
                      fontWeight: '600',
                      fontFamily: bannerStyles.fontFamily ?? 'sans-serif',
                    }
              }
              onClick={() => handleNavbar(3)}
              onMouseEnter={(e) => (e.currentTarget.style.color = buttonColor)}
              onMouseLeave={(e) => {
                e.currentTarget.style.color = selectedNavItem === 3 ? buttonColor : '#414141';
              }}
            >
              {selectedLanguage === 'en'
                ? cookieUserData.banner_configuration.bannerDesign.aboutTabHeading
                : translatedData?.banner_configuration?.bannerDesign?.aboutTabHeading || 'About'}
            </button>
          </div>

          {/* Cookie Banner Content */}
          <div
            key={contentKey}
            className={styles.cookieWallBannerContent}
            style={{
              opacity: isAnimating ? 0 : 1,
              transform: isAnimating ? 'translateY(10px)' : 'translateY(0)',
              transition: 'opacity 0.3s ease, transform 0.3s ease',
            }}
          >
            {renderContent()}
          </div>

          {/* Cookie Banner Footer */}
          <div
            className={styles.cookieWallBannerFooter}
            style={{
              borderTop: '1px solid rgba(0,0,0,0.12)', // ensure top border visible
              background: 'inherit',
              paddingTop: '10px',
              position: 'sticky',
              bottom: 0,
              boxSizing: 'border-box',
              display: 'flex',
              alignContent: 'center',
            }}
          >
            <div
              className={styles.cookieWallBannerFooterContent}
              style={{
                display: 'flex',
                flexWrap: isMobileDevice ? 'nowrap' : 'wrap', // wrap on desktop
                gap: isMobileDevice ? 12 : 8,
                rowGap: 8,
                justifyContent: 'flex-end',
                alignItems: isMobileDevice ? 'stretch' : 'center',
                width: '100%',
              }}
            >
              {(isFooterLayoutDialog ? preferenceModalCtas : ctas)?.map((btn, i) => {
                const styleType = isFooterLayoutDialog
                  ? (cookieUserData?.banner_configuration?.bannerDesign
                      ?.preferenceModalButtonStyles?.[btn.key] ?? 'primary')
                  : (cookieUserData?.banner_configuration?.bannerDesign?.buttonStyles?.[btn.key] ??
                    'primary');
                const isPrimary = styleType === 'primary';

                const activeArray = isFooterLayoutDialog ? preferenceModalCtas : ctas;
                const style: React.CSSProperties = {
                  ...btnBase,
                  backgroundColor: isPrimary ? buttonColor : 'transparent',
                  color: isPrimary ? '#fff' : buttonColor,
                  border: isPrimary ? 'none' : `1.5px solid ${buttonColor}`,
                  padding: '8px 48px',
                  animation: 'fadeInUp .6s ease-out both',
                  animationDelay: `${0.1 * (i + 1)}s`,
                  ...(isMobileDevice && {
                    width: '100%',
                    whiteSpace: 'normal', // allow multi-line on full-width mobile buttons
                  }),
                  ...(activeArray?.length === 3 &&
                    !isMobileDevice && {
                      width: '32%',
                    }),
                };

                return (
                  <button
                    key={btn.key}
                    className={styles.cookieWallBannerFooterButton}
                    style={style}
                    onMouseEnter={(e) => {
                      e.currentTarget.style.opacity = '0.9';
                      e.currentTarget.style.transform = 'translateY(-2px)';
                    }}
                    onMouseLeave={(e) => {
                      e.currentTarget.style.opacity = '1';
                      e.currentTarget.style.transform = 'translateY(0)';
                    }}
                    onClick={btn.onClick}
                  >
                    {btn.label}
                  </button>
                );
              })}
            </div>
          </div>
        </div>
      )}
    </div>
  );
  // Render Footer Banner
  const renderFooterBanner = () => (
    <div
      style={{
        position: 'fixed',
        left: 0,
        right: 0,
        bottom: 0,
        zIndex: 2147483647,
        transform: isVisible ? 'translateY(0)' : 'translateY(100%)',
        transitionProperty: 'transform',
        transitionDuration: '500ms',
        willChange: 'transform',
      }}
    >
      {isLoadingTranslations && selectedLanguage !== 'en' ? (
        <FooterBannerLoader />
      ) : (
        <div
          ref={footerRef}
          className={[
            styles.cookieFooterBanner,
            styles.isolated,
            footerReady ? styles.isReady : '',
            footerReady ? styles.animIn : '',
            styles.motionShadowLite,
          ].join(' ')}
          style={bannerStyles}
          onAnimationEnd={(e) => {
            e.currentTarget.classList.remove(styles.animIn, styles.motionShadowLite);
          }}
        >
          <div
            style={{
              position: 'relative',
              display: 'flex',
              height: '100%',
              width: '100%',
              flexDirection: 'row',
              flexWrap: 'wrap',
              justifyContent: 'space-between',
            }}
          >
            <div
              style={{
                display: 'flex',
                height: 'fit-content',
                width: '100%',
                flexDirection: 'column',
                gap: '8px', // gap-2 becomes 8px
              }}
            >
              <div
                style={{
                  display: 'flex',
                  width: '100%',
                  flexDirection: 'row',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  gap: '16px', // gap-4 becomes 16px
                }}
              >
                <div
                  style={{
                    display: 'flex',
                    flexDirection: isMobileDevice ? 'column' : 'row',
                    alignItems: isMobileDevice ? 'flex-start' : 'center',
                    gap: isMobileDevice ? '12px' : '8px',
                    fontSize: isMobileDevice ? '14px' : (bannerStyles.fontSize ?? '16px'),
                    width: '100%',
                    animation: 'fadeInUp 0.6s ease-out',
                    animationDelay: '0.2s',
                    animationFillMode: 'both',
                  }}
                >
                  {cookieUserData.banner_configuration.bannerDesign.logoUrl &&
                    cookieUserData.banner_configuration.bannerDesign.showLogo === 'true' && (
                      <img
                        src={cookieUserData.banner_configuration.bannerDesign.logoUrl}
                        // alt="company_logo"
                        // style={{
                        //   // maxHeight: isMobileDevice ? '40px' : '60px',
                        //   maxWidth: isMobileDevice ? '80px' : '150px',
                        //   objectFit: 'contain',
                        // }}
                        alt="Brand"
                        style={{
                          width: isMobileDevice
                            ? '40px'
                            : (cookieUserData.banner_configuration.bannerDesign.logoSize?.width ??
                              '136px'),

                          height: isMobileDevice
                            ? 'auto'
                            : (cookieUserData.banner_configuration.bannerDesign.logoSize?.height ??
                              '70px'),
                          objectFit: 'contain',
                        }}
                        decoding="async"
                        fetchPriority="low"
                      />
                    )}
                  <p
                    style={{
                      color: buttonColor,
                      fontSize: isMobileDevice ? '20px' : '24px',
                      fontWeight: 600,
                      margin: 0,
                      lineHeight: isMobileDevice ? '1.2' : '1.4',
                    }}
                  >
                    {selectedLanguage === 'en'
                      ? cookieUserData.banner_title
                      : translatedData?.banner_title}
                  </p>
                </div>

                {/* Desktop: Language dropdown then close icon in flex */}
                {!isMobileDevice && (
                  <>
                    {cookieUserData?.banner_configuration?.bannerDesign?.showLanguageDropdown && (
                      <select
                        className={styles.cookieWallBannerLanguageSelector}
                        value={selectedLanguage}
                        onChange={(e) => setSelectedLanguage(e.target.value)}
                        style={{
                          fontSize: '14px',
                          padding: '8px',
                          width: '100px',
                          marginTop: '0',
                        }}
                      >
                        {languages?.map((lang) => (
                          <option
                            value={lang?.language_code}
                            onClick={() => setSelectedLanguage(lang?.language_code)}
                            key={lang?.language_code}
                          >
                            {lang?.language ? lang?.language : lang?.language_code}
                          </option>
                        ))}
                      </select>
                    )}
                    {(cookieUserData?.banner_configuration?.bannerDesign?.allowBannerClose ??
                      true) && (
                      <button
                        onClick={handleClose}
                        style={{
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          width: '24px',
                          height: '24px',
                          borderRadius: '50%',
                          border: 'none',
                          background: 'transparent',
                          cursor: 'pointer',
                          color: bannerStyles.color,
                          transition: 'background-color 0.2s',
                          marginLeft: '8px',
                        }}
                        onMouseEnter={(e) =>
                          (e.currentTarget.style.backgroundColor = 'rgba(0,0,0,0.1)')
                        }
                        onMouseLeave={(e) =>
                          (e.currentTarget.style.backgroundColor = 'transparent')
                        }
                        aria-label="Close banner"
                      >
                        <svg
                          xmlns="http://www.w3.org/2000/svg"
                          width="16"
                          height="16"
                          viewBox="0 0 24 24"
                          fill="none"
                          stroke="#4B5563"
                          strokeWidth="4"
                          strokeLinecap="round"
                          strokeLinejoin="round"
                        >
                          <line x1="18" y1="6" x2="6" y2="18"></line>
                          <line x1="6" y1="6" x2="18" y2="18"></line>
                        </svg>
                      </button>
                    )}
                  </>
                )}

                {/* Mobile: Close icon then language dropdown stacked vertically */}
                {isMobileDevice && (
                  <div
                    style={{
                      display: 'flex',
                      flexDirection: 'column',
                      alignItems: 'flex-end',
                      gap: '8px',
                    }}
                  >
                    {(cookieUserData?.banner_configuration?.bannerDesign?.allowBannerClose ??
                      true) && (
                      <button
                        onClick={handleClose}
                        style={{
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          width: '20px',
                          height: '20px',
                          borderRadius: '50%',
                          border: 'none',
                          background: 'transparent',
                          cursor: 'pointer',
                          color: bannerStyles.color,
                          transition: 'background-color 0.2s',
                        }}
                        onMouseEnter={(e) =>
                          (e.currentTarget.style.backgroundColor = 'rgba(0,0,0,0.1)')
                        }
                        onMouseLeave={(e) =>
                          (e.currentTarget.style.backgroundColor = 'transparent')
                        }
                        aria-label="Close banner"
                      >
                        <svg
                          xmlns="http://www.w3.org/2000/svg"
                          width="14"
                          height="14"
                          viewBox="0 0 24 24"
                          fill="none"
                          stroke="#4B5563"
                          strokeWidth="4"
                          strokeLinecap="round"
                          strokeLinejoin="round"
                        >
                          <line x1="18" y1="6" x2="6" y2="18"></line>
                          <line x1="6" y1="6" x2="18" y2="18"></line>
                        </svg>
                      </button>
                    )}
                    {cookieUserData?.banner_configuration?.bannerDesign?.showLanguageDropdown && (
                      <select
                        className={styles.cookieWallBannerLanguageSelector}
                        value={selectedLanguage}
                        onChange={(e) => setSelectedLanguage(e.target.value)}
                        style={{
                          fontSize: '12px',
                          padding: '6px',
                          width: '80px',
                          marginTop: '0',
                        }}
                      >
                        {languages?.map((lang) => (
                          <option
                            value={lang?.language_code}
                            onClick={() => setSelectedLanguage(lang?.language_code)}
                            key={lang?.language_code}
                          >
                            {lang?.language ? lang?.language : lang?.language_code}
                          </option>
                        ))}
                      </select>
                    )}
                  </div>
                )}
              </div>
              <p
                style={{
                  height: 'fit-content',
                  fontSize: isMobileDevice ? '14px' : (bannerStyles.fontSize ?? '16px'),
                  lineHeight: isMobileDevice ? '1.4' : '1.5',
                  margin: 0,
                  marginTop: isMobileDevice ? '8px' : '0',
                  animation: 'fadeInUp 0.6s ease-out',
                  animationDelay: '0.4s',
                  animationFillMode: 'both',
                }}
              >
                {selectedLanguage === 'en' ? (
                  <div dangerouslySetInnerHTML={{ __html: cookieUserData.banner_description }} />
                ) : (
                  <div
                    dangerouslySetInnerHTML={{
                      __html: translatedData?.banner_description || '',
                    }}
                  />
                )}
              </p>
            </div>

            <div
              style={{
                display: 'flex',
                width: '100%',
                // right-align the CTA group
                justifyContent: isMobileDevice ? 'stretch' : 'flex-end',
                marginTop: isMobileDevice ? 16 : 8,
              }}
            >
              <div
                style={{
                  display: 'flex',
                  flexDirection: isMobileDevice ? 'column' : 'row',
                  // ✅ Allow wrapping on desktop too so buttons never overflow
                  flexWrap: isMobileDevice ? 'nowrap' : 'wrap',
                  alignItems: isMobileDevice ? 'stretch' : 'center',
                  justifyContent: 'flex-end',
                  // ✅ Use row/column gaps for nicer wrapping
                  gap: isMobileDevice ? 12 : 8,
                  rowGap: 8,
                  // ✅ Let content flow instead of clipping
                  width: isMobileDevice ? '100%' : 'auto',
                  maxWidth: '100%',
                  overflowX: 'visible', // was 'hidden'
                  animation: 'fadeInUp 0.6s ease-out',
                  animationDelay: '0.6s',
                  animationFillMode: 'both',
                }}
              >
                {ctas?.map((btn, i) => {
                  const styleType =
                    cookieUserData?.banner_configuration?.bannerDesign?.buttonStyles?.[btn.key] ??
                    'primary';

                  const isPrimary = styleType === 'primary';

                  const buttonStyle: React.CSSProperties = {
                    ...btnBase,
                    backgroundColor: isPrimary ? buttonColor : 'transparent',
                    color: isPrimary ? 'white' : buttonColor,
                    border: isPrimary ? 'none' : `1.5px solid ${buttonColor}`,
                    animationDelay: `${0.1 * (i + 1)}s`,
                    // ✅ Make buttons play nice when wrapping
                    whiteSpace: 'nowrap',
                    minWidth: 100,
                    maxWidth: '100%',
                    ...(isMobile && {
                      height: '44px',
                      padding: '10px 14px',
                      fontSize: '14px',
                      width: '100%',
                      whiteSpace: 'normal', // allow text to wrap on mobile full width
                    }),
                    boxSizing: 'border-box',
                    // ✅ Add shadow above the footer
                    boxShadow: '0 -4px 12px rgba(0, 0, 0, 0.08)',
                  };

                  return (
                    <button
                      key={btn.key}
                      type="button"
                      style={buttonStyle}
                      onMouseEnter={(e) => {
                        e.currentTarget.style.opacity = '0.9';
                        e.currentTarget.style.transform = 'translateY(-2px)';
                      }}
                      onMouseLeave={(e) => {
                        e.currentTarget.style.opacity = '1';
                        e.currentTarget.style.transform = 'translateY(0)';
                      }}
                      onClick={btn.onClick}
                    >
                      {btn.label}
                    </button>
                  );
                })}
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );

  // Render Floating Logo
  const renderFloatingLogo = () => {
    if (!shouldShowFloatingLogo) return null;
    return (
      <Suspense fallback={null}>
        <DraggableLogo onClick={handleOpenDialog} initialPosition={{ x: 0, y: 0 }} />
      </Suspense>
    );
  };

  // Main return with conditional rendering
  return (
    <>
      {shouldShowWallBanner && renderWallBanner()}
      {shouldShowFooterBanner && renderFooterBanner()}
      {shouldShowFloatingLogo &&
        cookieUserData?.banner_configuration?.bannerDesign?.floatingLogo?.enable &&
        renderFloatingLogo()}
    </>
  );
};

export default CookieBanner;
