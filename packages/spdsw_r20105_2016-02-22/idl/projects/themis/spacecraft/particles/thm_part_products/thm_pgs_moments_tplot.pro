;+
;Procedure:
;  thm_pgs_moments_tplot
;
;
;Purpose:
;  Creates tplot variables from moments structures
;
;
;Arguments:
;  moments:  Array of moments structures returned from moments_3d 
;  
;  
;Keywords:
;  get_error: Flag indicating that the current moment structure
;             contains error estimates.
;  prefix: Tplot variable name prefix (e.g. 'tha_peif_')
;  suffix: Tplot variable name suffix
;  tplotnames: Array of tplot variable names created by the parent 
;              routine.  Any tplot variables created in this routine
;              should have their names appended to this array.
;  
;
;Notes:
;  Much of this code was copied from thm_part_moments.pro
;
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-04-07 12:20:35 -0700 (Mon, 07 Apr 2014) $
;$LastChangedRevision: 14762 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/thm_part_products/thm_pgs_moments_tplot.pro $
;-
pro thm_pgs_moments_tplot, moments, $
                           get_error=get_error, $
                           prefix=prefix0, $
                           suffix=suffix0, $
                           tplotnames=tplotnames, $
                           _extra = _extra

    compile_opt idl2, hidden


  if undefined(prefix0) then prefix='' else prefix=prefix0
  if undefined(suffix0) then suffix='' else suffix=suffix0
  if keyword_set(get_error) then suffix = '_sigma'+suffix


  ;Get names of valid moments
  if keyword_set(get_error) then begin
    ;error estimates produced by moments_3d
    valid_moments = ['avgtemp', 'density', 'eflux', 'flux', $
                     'mftens', 'ptens', 'sc_current', $
                     'velocity', 'vthermal'] 
  endif else begin
    ;moments produced by moments_3d
    valid_moments = ['avgtemp', 'density', 'eflux', 'flux', $
                     'mftens', 'ptens', 'sc_current', $
                     'velocity', 'vthermal', $
                     'magf', 'magt3', 't3', 'sc_pot', 'symm', $
                     'symm_theta', 'symm_phi', 'symm_ang']
  endelse


  ;Create tplot variables
  ;-----------------------------------------


  ;loop over valid names to create variables
  ;options will be set later
  for i=0, n_elements(valid_moments)-1 do begin
  
    tname = prefix + valid_moments[i] + suffix
    
    mom_data = struct_value(moments, valid_moments[i])
    If(n_elements(mom_data) Gt 1) Then Begin
       mom_data = reform(transpose(temporary(mom_data))) ;copied from tpm
    Endif
    
    store_data, tname, data= {x:moments.time, y:mom_data} ;,verbose=0
    
    if size(/n_dimen,mom_data) gt 1 then options,tname,colors='bgr',/def
    
    mom_tnames = undefined(mom_tnames) ? tname:array_concat(mom_tnames,tname)
    
  endfor
  
  
  ;Set tplot options
  ;-----------------------------------------
  
  ;set ranges and subtitles (mostly copied from thm_part_moments)
  options,strfilter(mom_tnames,'*_density'+suffix),/def ,/ystyle,/ylog,ysubtitle='!c[1/cc]'
  options,strfilter(mom_tnames,'*_velocity'+suffix),/def ,yrange=[-800,800.],/ystyle,ysubtitle='!c[km/s]'
  options,strfilter(mom_tnames,'*_flux'+suffix),/def ,yrange=[-1e8,1e8],/ystyle,ysubtitle='!c[#/s/cm2 ??]'
  options,strfilter(mom_tnames,'*t3'+suffix),/def ,yrange=[1,10000.],/ystyle,/ylog,ysubtitle='!c[eV]'
  options,strfilter(mom_tnames,'*tens'+suffix),/def ,colors='bgrmcy',ysubtitle='!c[eV/cm^3]'
  
  ;set units (copied from thm_part_moments)
  thm_new_units, strfilter(mom_tnames, '*_density'+suffix), units_in = '1/cm^3'
  thm_new_units, strfilter(mom_tnames,'*_velocity'+suffix), units_in = 'km/s'
  thm_new_units, strfilter(mom_tnames,'*_vthermal'+suffix), units_in = 'km/s'
  thm_new_units, strfilter(mom_tnames,'*_flux'+suffix), units_in = '#/s/cm^2'
  thm_new_units, strfilter(mom_tnames,'*t3'+suffix), units_in = 'eV'
  thm_new_units, strfilter(mom_tnames,'*_avgtemp'+suffix), units_in = 'eV'
  thm_new_units, strfilter(mom_tnames,'*_sc_pot'+suffix), units_in = 'V'
  thm_new_units, strfilter(mom_tnames,'*_eflux'+suffix), units_in = 'eV/(cm^2-s)'
  thm_new_units, strfilter(mom_tnames,'*tens'+suffix), units_in = 'eV/cm^3'
  thm_new_units, strfilter(mom_tnames,'*_symm_theta'+suffix), units_in = 'degrees'
  thm_new_units, strfilter(mom_tnames,'*_symm_phi'+suffix), units_in = 'degrees'
  thm_new_units, strfilter(mom_tnames,'*_symm_ang'+suffix), units_in = 'degrees'
  thm_new_units, strfilter(mom_tnames,'*_magf'+suffix), units_in = 'nT'
  
  ;set coordinates (copied from thm_part_moments)
  thm_new_coords, strfilter(mom_tnames,'*_velocity'+suffix), coords_in = 'DSL'
  thm_new_coords, strfilter(mom_tnames,'*_flux'+suffix), coords_in = 'DSL'
  thm_new_coords, strfilter(mom_tnames,'*_t3'+suffix), coords_in = 'DSL'
  thm_new_coords, strfilter(mom_tnames,'*_eflux'+suffix), coords_in = 'DSL'
  thm_new_coords, strfilter(mom_tnames,'*tens'+suffix), coords_in = 'DSL'
  thm_new_coords, strfilter(mom_tnames,'*_magf'+suffix), coords_in = 'DSL'
  thm_new_coords, strfilter(mom_tnames,'*_magt3'+suffix), coords_in = 'FA'

  
  ;Output the names of created tplot variables
  ;-----------------------------------------
  tplotnames = undefined(tplotnames) ? mom_tnames:array_concat(tplotnames,mom_tnames)


  return

end
