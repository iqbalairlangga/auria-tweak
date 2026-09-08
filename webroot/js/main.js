// Auria Tweak - WebUI Logic
'use strict';

/* ================= Bridge support =================
 * KernelSU / MMRL ........ window.kuband (callback-style exec)
 * ReSukiSU / SukiSU/SukiSU-Next lineage .. window.ksu (WebUI-Next API:
 *   sync exec(cmd) -> stdout, or exec(cmd, "cbName") -> cb(exitCode,out,err))
 */
const MOD_PATH = '/data/adb/modules/auria_tweak';
const CFG  = MOD_PATH + '/config.sh';
const CLIC = MOD_PATH + '/cli.sh';

const BRIDGES = [
  { kind: 'kuband',  get: () => window.kuband },
  { kind: 'kuband',  get: () => (window.MMRLWebUI && window.MMRLWebUI.kuband) || null },
  { kind: 'ksu',     get: () => window.ksu },
];

function api() {
  for (const b of BRIDGES) { const o = b.get(); if (o) return { kind: b.kind, handle: o }; }
  return null;
}

function exec(cmd) {
  return new Promise((resolve) => {
    const a = api();
    if (!a) return resolve({ errno: -1, stdout: '', stderr: 'no-bridge' });
    const resolveResult = (errno, stdout, stderr) =>
      resolve({ errno: errno || 0, stdout: stdout || '', stderr: stderr || '' });

    if (a.kind === 'ksu') {
      // WebUI-Next: async via a globally-registered callback name.
      try {
        const cbName = '__auria_exec_' + (Math.random() * 1e9 | 0);
        window[cbName] = (code, out, err) => { delete window[cbName]; resolveResult(code, out, err); };
        a.handle.exec(cmd, cbName);
        return;
      } catch (e) {
        // Fallback: sync exec returning stdout string.
        try {
          const r = a.handle.exec(cmd);
          if (typeof r === 'string') return resolveResult(0, r, '');
        } catch (e2) { /* fall through */ }
        return resolve({ errno: -1, stdout: '', stderr: String(e) });
      }
    }

    // kuband: callback-style.
    try {
      a.handle.exec(cmd, (code, stdout, stderr) => resolveResult(code, stdout, stderr));
    } catch (e) {
      // Some kuband builds return a Promise.
      const r = a.handle.exec(cmd);
      if (r && typeof r.then === 'function') {
        r.then(x => resolve({ errno: 0, stdout: typeof x === 'string' ? x : (x?.stdout || x?.result || ''), stderr: '' }))
         .catch(() => resolve({ errno: -1, stdout: '', stderr: String(e) }));
      } else {
        resolve({ errno: -1, stdout: '', stderr: String(e) });
      }
    }
  });
}

/* ================= State ================= */
const DEFAULTS = {
  AURIA_PROFILE: 'balanced',
  AURIA_THERMAL: '1',
  AURIA_CHARGING: '1',
  AURIA_CHARGE_CURRENT: '2000000',
  AURIA_DISPLAY: '1',
  AURIA_REFRESH: '0',
  AURIA_ANIMATION: '1',
  AURIA_RENDER: '1',
  AURIA_CPU_GOVERNOR: 'performance',
  AURIA_IO: '1',
  AURIA_VM: '1',
  AURIA_LOG_ENABLE: '1',
};
let cfg = { ...DEFAULTS };
let dirty = false;

const toast = (msg, kind = '') => {
  const t = document.getElementById('toast');
  t.textContent = msg; t.className = 'toast show ' + kind;
  setTimeout(() => t.classList.remove('show'), 2200);
};

/* ================= Parse config ================= */
async function loadConfig() {
  const r = await exec('cat ' + CFG);
  if (r.stderr) {
    // No read permission (flat path) or missing bridge: keep defaults, still render.
    const b = api();
    toast(b ? 'Tidak dapat membaca config' : 'WebUI: aktifkan di manager', b ? 'err' : '');
    return renderAll();
  }
  const txt = r.stdout;
  for (const line of txt.split('\n')) {
    if (!line || line.startsWith('#')) continue;
    const i = line.indexOf('=');
    if (i < 0) continue;
    const k = line.slice(0, i).trim(), v = line.slice(i + 1).trim();
    if (k in DEFAULTS) cfg[k] = v;
  }
  renderAll();
}

function renderAll() {
  document.querySelectorAll('.profile').forEach(p => {
    const act = p.dataset.p === cfg.AURIA_PROFILE;
    p.classList.toggle('active', act);
    p.onclick = () => { selectProfile(p.dataset.p); };
  });
  document.querySelectorAll('.toggle').forEach(tg => {
    const k = tg.dataset.key, sw = tg.querySelector('.switch');
    if (k && sw) sw.classList.toggle('on', cfg[k] === '1');
    tg.onclick = (e) => { if (e.target.closest('.toggle') === tg) flip(tg, k); };
  });
  document.querySelectorAll('.seg').forEach(seg => {
    const k = seg.dataset.key;
    seg.querySelectorAll('button').forEach(b => {
      b.classList.toggle('on', cfg[k] === b.dataset.v);
      b.onclick = () => setKey(k, b.dataset.v);
    });
  });
  const sel = document.getElementById('AURIA_REFRESH');
  if (sel) sel.value = cfg.AURIA_REFRESH;
  const gov = document.getElementById('AURIA_CPU_GOVERNOR');
  if (gov) gov.value = cfg.AURIA_CPU_GOVERNOR;
  const cur = document.getElementById('AURIA_CHARGE_CURRENT');
  if (cur) { cur.value = cfg.AURIA_CHARGE_CURRENT; document.getElementById('curval').textContent = cfg.AURIA_CHARGE_CURRENT + ' µA'; }
}
function selectProfile(p) { if (cfg.AURIA_PROFILE === p) return; cfg.AURIA_PROFILE = p; dirty = true; renderAll(); applyProfile(p); }
function flip(tg, k) { cfg[k] = cfg[k] === '1' ? '0' : '1'; dirty = true; renderAll(); }
function setKey(k, v) { cfg[k] = String(v); dirty = true; renderAll(); }

/* ================= Save ================= */
function sedKey(k, v) {
  const esc = String(v).replace(/([&\\|])/g, '\\$1');
  return exec("sed -i 's|^" + k + "=.*|" + k + "=" + esc + "|' " + CFG);
}

async function saveConfig() {
  cfg.AURIA_CHARGE_CURRENT = String(Math.max(0, parseInt(document.getElementById('AURIA_CHARGE_CURRENT').value || '0', 10)));
  cfg.AURIA_REFRESH = document.getElementById('AURIA_REFRESH').value;
  cfg.AURIA_CPU_GOVERNOR = document.getElementById('AURIA_CPU_GOVERNOR').value;
  await exec('cp ' + CFG + ' ' + CFG + '.bak');
  for (const k of Object.keys(DEFAULTS)) {
    const r = await sedKey(k, cfg[k]);
    if (r.stderr) { dirty = true; return r; }
  }
  dirty = false;
  return { errno: 0, stdout: '', stderr: '' };
}

async function applyProfile(p) {
  const r = await sedKey('AURIA_PROFILE', p);
  toast('Terapkan profil ' + p + '…', 'ok');
  const a = await exec('sh ' + CLIC + ' "' + p + '" >/dev/null 2>&1 &');
  setTimeout(() => {
    const ok = !(r.stderr || a.stderr);
    toast(ok ? 'Profil ' + p + ' aktif' : 'Gagal menerapkan ' + p, ok ? 'ok' : 'err');
  }, 800);
}

async function applyNow() {
  await saveConfig();
  toast('Terapkan tweak → ' + cfg.AURIA_PROFILE + '…', 'ok');
  const r = await exec('sh ' + CLIC + ' "' + cfg.AURIA_PROFILE + '" >/dev/null 2>&1 &');
  setTimeout(() => toast('Diterapkan (' + cfg.AURIA_PROFILE + '). Log: /data/adb/auria_tweak.log', r.stderr ? 'err' : 'ok'), 800);
}

async function saveAndReboot() {
  const r = await saveConfig();
  toast('Config disimpan, reboot…', 'ok');
  setTimeout(() => exec('reboot'), 600);
}

/* ================= Boot ================= */
(async function init() {
  if (!api()) {
    document.body.classList.add('busy');
    toast('WebUI: aktifkan di manager (KSU/MMRL/ReSukiSU)', 'err');
  }
  const p = await exec('getprop ro.board.platform');
  const hw = (p.stdout || '').trim();
  document.getElementById('soc').textContent = /^mt/i.test(hw) ? 'MediaTek' : (/sm|sdm|msm|kona|lito|bengal|lahaina|taro|kalama/i.test(hw) ? 'Snapdragon' : (hw || 'unk'));
  document.getElementById('plat').textContent = hw || '?';
  document.getElementById('applyBtn').onclick = applyNow;
  document.getElementById('saveBtn').onclick = saveAndReboot;
  await loadConfig();
})();