export default function CalWattBrand({ subtitle, className = '' }) {
  return <span className={`brand-inner ${className}`.trim()}>
    <img className="brand-mark" src="/calwatt-mark.svg" alt="" />
    <span>CalWatt{subtitle && <small>{subtitle}</small>}</span>
  </span>;
}
