'use client';

// What the public pages read without signing in (decision 0024): prices,
// support contacts, the website's words, company details, logo, stamp,
// signature and the published legal documents. Every read falls back to the
// built-in default, so the pages always show something.

import { collection, doc, getDoc, getDocs } from 'firebase/firestore';
import { useEffect, useState } from 'react';
import { firebase } from './firebase.ts';
import { configFromDoc, defaultConfig, offeredPlans, planFromDoc, samplePlans, type Plan, type PlatformConfig } from './platform.ts';
import { companyFromDoc, defaultSite, siteFromDoc, type Company, type SiteContent } from './site.ts';
import { DEFAULT_LEGAL, DEFAULT_SIGNATORY, OPERATOR, legalFromDoc, type LegalDoc, type LegalKind } from '../shared/legal.ts';

export type AssetName = 'logo' | 'stamp' | 'signature';
export interface Asset {
  dataUrl: string;
  url: string;
}

export const defaultCompany: Company = {
  company: OPERATOR.company,
  address: OPERATOR.address,
  website: OPERATOR.website,
  tin: '',
  signatoryName: DEFAULT_SIGNATORY.name,
  signatoryTitle: DEFAULT_SIGNATORY.title,
};

async function safe<T>(fn: () => Promise<T>, fallback: T): Promise<T> {
  try {
    return await fn();
  } catch {
    return fallback;
  }
}

export async function loadAsset(name: AssetName): Promise<Asset | null> {
  return safe(async () => {
    const d = (await getDoc(doc(firebase().db, 'platformAssets', name))).data();
    const dataUrl = typeof d?.dataUrl === 'string' ? d.dataUrl : '';
    const url = typeof d?.url === 'string' ? d.url : '';
    return dataUrl || url ? { dataUrl, url } : null;
  }, null);
}

export const loadCompany = () => safe(async () => companyFromDoc((await getDoc(doc(firebase().db, 'platform', 'company'))).data(), defaultCompany), defaultCompany);
export const loadSite = () => safe(async () => siteFromDoc((await getDoc(doc(firebase().db, 'platform', 'site'))).data()), defaultSite);
export const loadPublicConfig = () => safe(async () => configFromDoc((await getDoc(doc(firebase().db, 'platform', 'config'))).data()), defaultConfig);
export const loadPublicPlans = () =>
  safe(async () => {
    const s = await getDocs(collection(firebase().db, 'plans'));
    const plans = offeredPlans(s.docs.map((d) => planFromDoc(d.id, d.data())));
    return plans.length ? plans : samplePlans;
  }, samplePlans);
export const loadLegal = (kind: LegalKind) =>
  safe(async () => {
    const snap = await getDoc(doc(firebase().db, 'legalDocs', kind));
    return snap.exists() ? legalFromDoc(kind, snap.data()) : DEFAULT_LEGAL[kind];
  }, DEFAULT_LEGAL[kind]);

/** Loads once on the page; `undefined` while loading. */
export function useOnce<T>(load: () => Promise<T>): T | undefined {
  const [v, setV] = useState<T | undefined>(undefined);
  useEffect(() => {
    let live = true;
    void load().then((x) => live && setV(x));
    return () => {
      live = false;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);
  return v;
}

export interface PublicInfo {
  config: PlatformConfig;
  company: Company;
  logo: Asset | null;
}

export const loadPublicInfo = async (): Promise<PublicInfo> => {
  const [config, company, logo] = await Promise.all([loadPublicConfig(), loadCompany(), loadAsset('logo')]);
  return { config, company, logo };
};

export type { LegalDoc, Plan, SiteContent };
