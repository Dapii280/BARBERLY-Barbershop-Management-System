// Rumus rincian biaya booking (integrasi Matematika + KIK)
const round2 = (value) => Math.round((Number(value) + Number.EPSILON) * 100) / 100;

// Rate dibaca ulang setiap pemanggilan agar perubahan .env langsung terpakai
const getRates = () => {
  const ppnRate = Number(process.env.PPN_RATE);
  const taxDeductionRate = Number(process.env.TAX_DEDUCTION_RATE);

  return {
    ppnRate: Number.isFinite(ppnRate) && ppnRate >= 0 ? ppnRate : 0.11,
    taxDeductionRate:
      Number.isFinite(taxDeductionRate) && taxDeductionRate >= 0 ? taxDeductionRate : 0.02,
  };
};

/**
 * Menghitung rincian biaya dari daftar harga layanan.
 * subtotal      = total harga layanan
 * ppn_amount    = subtotal * PPN_RATE
 * tax_deduction = subtotal * TAX_DEDUCTION_RATE
 * total_price   = pembulatan(subtotal + ppn_amount - tax_deduction)
 */
const calculateBill = (prices = []) => {
  const { ppnRate, taxDeductionRate } = getRates();
  const subtotal = round2(prices.reduce((total, price) => total + Number(price || 0), 0));
  const ppn_amount = round2(subtotal * ppnRate);
  const tax_deduction = round2(subtotal * taxDeductionRate);
  const total_price = Math.round(subtotal + ppn_amount - tax_deduction);

  return {
    subtotal,
    ppn_amount,
    tax_deduction,
    total_price,
    ppn_rate: ppnRate,
    tax_deduction_rate: taxDeductionRate,
  };
};

module.exports = { calculateBill, getRates, round2 };
