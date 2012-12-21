; Iterate kj with rsfwc with file based communiction

pro kj_iterate, jPFile=jPFile, itStartNo=itStartNo, nIterations=nIterations

	if keyword_set(itStartNo) then itStart=itStartNo else itStart=0
	if keyword_set(nIterations) then nIt=nIterations else nIt=20

	cd, current=runDir
	runIdent = file_baseName(runDir)
	rsfwcCfg = kj_read_rsfwc_cfg('data/rsfwc_input.pro')
	kjCfg = kj_read_cfg('kj.cfg')

	jAmpMax = 50.0
	jAmpStep = 50.0 

	nk =6
	eGuessFileList = strArr(nk)

	for it=itStart,itStart+nIt-1 do begin

		for k=0,nk-1 do begin

			print, 'Iteration: ', string(it,format='(i3.3)'),' of ', $
					string(itStart+nIt-1,format='(i3.3)'), ' and sub-it: ', $
					string(k,format='(i3.3)'), ' of ', string(nk-1,format='(i3.3)')

			thisIdent = runIdent+'_'+string(k+1,format='(i3.3)')
			lastIdent = runIdent+'_'+string(k+1-1,format='(i3.3)')

			rsfwcCfg.runIdent = thisIdent 
			rsfwcCfg.jAmp = ((k+1)*jAmpStep)<jAmpMax

			if(k eq 0 and not keyword_set(jPFile) ) then begin
				rsfwcCfg.kjInput=0 
				rsfwcCfg.kj_jP_fileName = ''
			endif else if(k eq 0 and keyword_set(jPFile) ) then begin
				print, 'Continuing wkh file ... ', jPFile
				rsfwcCfg.kjInput=1 
				rsfwcCfg.kj_jP_fileName = jPFile
			endif else begin
				rsfwcCfg.kjInput=1
				rsfwcCfg.kj_jP_fileName = 'kj_jP_'+lastIdent+'.nc'
			endelse

			kj_write_rsfwc_cfg, rsfwcCfg, k

			if(it eq itStart) then begin
				cd, 'data'
				spawn, 'idl -quiet run_rsfwc'
				cd, runDir
			endif

			kjCfg.eField_fName = 'data/rsfwc_1d_'+rsfwcCfg.runIdent+'.nc'
			eGuessFileList[k] = kjCfg.eField_fName
			kjCfg.runIdent = thisIdent 

			kj_write_kj_cfg, kjCfg, k

			spawn, '~/code/kineticj/bin/kineticj'
			spawn, 'idl -quiet run_kj_plot_current'
			spawn, 'cp output/kj_jP_'+thisIdent+'.nc data/'

		endfor

		; Read the previous n guesses and apply vector extrapolation

		eGuess = !null

		for k=0,nk-1 do begin

			cdfId = ncdf_open(eGuessFileList[k])

				ncdf_varget, cdfId, 'r', r 

				ncdf_varget, cdfId, 'e_r_re', er_re
				ncdf_varget, cdfId, 'e_r_im', er_im
				ncdf_varget, cdfId, 'e_p_re', ep_re
				ncdf_varget, cdfId, 'e_p_im', ep_im
				ncdf_varget, cdfId, 'e_z_re', ez_re
				ncdf_varget, cdfId, 'e_z_im', ez_im

			ncdf_close, cdfId

			nX = n_elements(r)

			eGuess = [[eGuess],[complex(er_re,er_im)]]

		endfor

		s = s_mpe(eGuess)

		p=plot(s,dim=[1200,400],buffer=1,color='b')
		for i=0,_k-1 do !null=plot(x[*,i],/over)
		p.save, 'tmpr.eps'

		p=plot(imaginary(s),dim=[1200,400],buffer=1,color='b')
		for i=0,_k-1 do !null=plot(imaginary(x[*,i]),/over)
		p.save, 'tmpi.eps'

		cdfId = ncdf_open(eGuessFileList[0],/write)
			e_r_re_id = nCdf_varid(cdfId, 'e_r_re')
			e_r_im_id = nCdf_varid(cdfId, 'e_r_im')
			nCdf_varPut, cdfId, e_r_re_id, s_re
			nCdf_varPut, cdfId, e_r_im_id, s_im
		nCdf_close, cdfId

		pr=plot(s_re,color='b',thick=2,buffer=1, dim=[1200,400])
		for k=0,nk-1 do begin
			!null=plot(real_part(eGuess[*,k]),/over)
		endfor
		pi=plot(s_im,color='b',thick=2,buffer=1, dim=[1200,400])
		for k=0,nk-1 do begin
			!null=plot(imaginary(eGuess[*,k]),/over)
		endfor
		pr.save, 'er.png'
		pi.save, 'ei.png'

		stop

	endfor

	stop

end


