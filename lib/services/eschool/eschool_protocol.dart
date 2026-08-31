/// Central boundary for assumptions corroborated by the August 2026 official
/// eSchool frontend. Update this file when the deployed protocol changes.
abstract final class EschoolProtocol {
  static const baseUrl = 'https://app.eschool.center/ec-server';
  static const clientVersion = 'v.4207';

  static const login = '/login';
  static const state = '/state';
  static const academicYears = '/yearplan/academyears';
  static const classesByUser = '/usr/getClassByUser';
  static const periods = '/dict/periods/0';
  static const diaryUnits = '/student/getDiaryUnits/';
  static const diaryPeriod = '/student/getDiaryPeriod_';
  static const personDiary = '/student/getPrsDiary';

  // The official frontend supports CAPTCHA, but the audit did not establish a
  // complete server response contract. Do not infer or automate a challenge
  // until a sanitized response-schema observation is available.
  static const captchaResponseContractObserved = false;

  // MFA_REQUIRED and its metadata are corroborated by current frontend code,
  // but were not triggered during the live audit.
  static const mfaLiveObserved = false;
}
