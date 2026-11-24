// Helper perhitungan waktu untuk jam selesai booking dan slot availability
const toMinutes = (time) => {
  const [hours, minutes] = String(time).split(':').map(Number);
  return hours * 60 + minutes;
};

const toTime = (minutes) => {
  const normalized = ((minutes % 1440) + 1440) % 1440;
  const hours = String(Math.floor(normalized / 60)).padStart(2, '0');
  const mins = String(normalized % 60).padStart(2, '0');
  return `${hours}:${mins}:00`;
};

// end_time = start_time + total duration_minutes (Matematika)
const addMinutes = (time, minutes) => toTime(toMinutes(time) + Number(minutes || 0));

const normalizeTime = (time) => {
  const [hours, minutes] = String(time).split(':');
  return `${String(hours).padStart(2, '0')}:${String(minutes).padStart(2, '0')}:00`;
};

const isValidDateString = (value) => {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(String(value))) return false;
  const date = new Date(`${value}T00:00:00Z`);
  return !Number.isNaN(date.getTime()) && date.toISOString().slice(0, 10) === value;
};

const isValidTimeString = (value) => /^([01]\d|2[0-3]):[0-5]\d(:[0-5]\d)?$/.test(String(value));

const todayString = () => {
  const now = new Date();
  const pad = (number) => String(number).padStart(2, '0');
  return `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}`;
};

const currentTimeString = () => {
  const now = new Date();
  const pad = (number) => String(number).padStart(2, '0');
  return `${pad(now.getHours())}:${pad(now.getMinutes())}:00`;
};

// Dua rentang waktu bertabrakan jika start A < end B dan end A > start B
const isOverlap = (startA, endA, startB, endB) =>
  toMinutes(startA) < toMinutes(endB) && toMinutes(endA) > toMinutes(startB);

module.exports = {
  toMinutes,
  toTime,
  addMinutes,
  normalizeTime,
  isValidDateString,
  isValidTimeString,
  todayString,
  currentTimeString,
  isOverlap,
};
