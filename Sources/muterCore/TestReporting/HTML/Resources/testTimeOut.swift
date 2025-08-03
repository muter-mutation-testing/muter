let testTimeout =
    """
    <svg class="time-out" role="img" viewBox="0 0 72 72">
    <title>$title$</title>
      <g>
        <path fill="#9B9B9A" stroke="none" d="M40.2139,31.1055c0.0039-0.002,0.0068-0.002,0.0107-0.002c0.0049-0.0019,0.0088-0.0039,0.0137-0.0058    C45.8926,29.6133,48,23.3076,48,19.6816V18H24v1.6816c0,3.626,2.1074,9.9317,7.7617,11.4161    c0.0049,0.0019,0.0088,0.0039,0.0137,0.0058c0.0039,0,0.0068,0,0.0107,0.002c1.792,0.4863,3.0996,1.5361,3.7491,2.8945h0.9296    C37.1143,32.6416,38.4219,31.5918,40.2139,31.1055z"/>
        <path fill="#9B9B9A" stroke="none" d="M47,55c-6.0742,0-11-4.9258-11-11c0,6.0742-4.9258,11-11,11h-1v4h24v-4H47z"/>
        <path fill="#a57939" stroke="none" d="M55,11c0,1.1001-0.9004,2-2,2H19c-1.0996,0-2-0.8999-2-2v-1c0-1.1001,0.9004-2,2-2h34c1.0996,0,2,0.8999,2,2    V11z"/>
        <path fill="#a57939" stroke="none" d="M55,62c0,1.0996-0.9004,2-2,2H19c-1.0996,0-2-0.9004-2-2v-1c0-1.0996,0.9004-2,2-2h34c1.0996,0,2,0.9004,2,2    V62z"/>
        <line x1="36" x2="36" y1="39" y2="44" fill="#FFFFFF" stroke="none" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="2"/>
        <path fill="none" stroke="#fff" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="2" d="M31,34c-7.2725-1.9092-10-9.5454-10-14.3184C21,14.9092,21,13,21,13"/>
        <path fill="none" stroke="#fff" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="2" d="M21,59c0,0,0-1.9092,0-6.6816C21,47.5459,23.7275,39.9092,31,38"/>
        <path fill="none" stroke="#fff" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="2" d="M31,38c1-0.2715,2-0.8945,2-2c0-1.1045-1-1.7285-2-2"/>
        <path fill="none" stroke="#fff" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="2" d="M41,34c7.2725-1.9092,10-9.5454,10-14.3184C51,14.9092,51,13,51,13"/>
        <path fill="none" stroke="#fff" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="2" d="M51,59c0,0,0-1.9092,0-6.6816C51,47.5459,48.2725,39.9092,41,38"/>
        <path fill="none" stroke="#fff" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="2" d="M41,38c-1-0.2715-2-0.8945-2-2c0-1.1045,1-1.7285,2-2"/>
        <path fill="none" stroke="#9B9B9A" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="2" d="M25,55c6.0742,0,11-4.9258,11-11c0,6.0742,4.9258,11,11,11"/>
        <path fill="none" stroke="#fff" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="2" d="M55,11c0,1.1001-0.9004,2-2,2H19c-1.0996,0-2-0.8999-2-2v-1c0-1.1001,0.9004-2,2-2h34c1.0996,0,2,0.8999,2,2V11z"/>
        <line x1="47" x2="25" y1="18" y2="18" fill="none" stroke="#9B9B9A" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="2"/>
        <path fill="none" stroke="#fff" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="2" d="M55,62c0,1.0996-0.9004,2-2,2H19c-1.0996,0-2-0.9004-2-2v-1c0-1.0996,0.9004-2,2-2h34c1.0996,0,2,0.9004,2,2V62z"/>
        <line x1="36" x2="36" y1="39" y2="44" fill="none" stroke="#9B9B9A" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="2"/>
      </g>
    </svg>
    """

let clockSvg =
    """
    <svg class="time-out" role="img" viewBox="0 0 72 72">
    <title>$title$</title>
    <g id="color">
      <line x1="50.258" x2="53.1419" y1="55.036" y2="59.8645" fill="#FFFFFF" stroke="none" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="2"/>
      <line x1="21.7419" x2="18.858" y1="55.036" y2="59.8645" fill="#FFFFFF" stroke="none" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="2"/>
      <path fill="#d0cfce" stroke="#d0cfce" stroke-miterlimit="10" stroke-width="2" d="M36,19"/>
      <path fill="#d0cfce" stroke="#d0cfce" stroke-miterlimit="10" stroke-width="2" d="M36,19"/>
      <path fill="#d0cfce" stroke="none" d="M46.1859,14.7917c2.2534-4.6476,4.2653-4.0842,6.1673-4.3168c1.2869-0.1573,6.4609,3.1641,6.4609,6.5799 s-2.2433,4.739-3.5597,5.4867"/>
      <path fill="#d0cfce" stroke="none" d="M25.8141,14.7917c-2.2533-4.6476-4.2652-4.0842-6.1672-4.3168c-1.287-0.1573-6.461,3.1641-6.461,6.5799 s2.2433,4.739,3.5597,5.4867"/>
      <circle cx="36" cy="36.2941" r="23" fill="#FFFFFF" stroke="none" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="2"/>
      <line x1="36.0257" x2="36.0257" y1="18.9893" y2="35.9893" fill="#FFFFFF" stroke="none" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="2"/>
      <line x1="35.9742" x2="29.9742" y1="35.9349" y2="46.3272" fill="#FFFFFF" stroke="none" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="2.0785"/>
    </g>
    <g id="hair"/>
    <g id="skin"/>
    <g id="skin-shadow"/>
    <g id="line">
      <path fill="none" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="2" d="M36,12.6326"/>
      <path fill="none" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="2" d="M36,19.0725"/>
      <path fill="none" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="2" d="M36,19.2478"/>
      <path fill="none" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="2" d="M36,12.7539"/>
      <line x1="50.258" x2="53.1419" y1="55.036" y2="59.8645" fill="none" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="2"/>
      <line x1="21.7419" x2="18.858" y1="55.036" y2="59.8645" fill="none" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="2"/>
      <path fill="none" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="2" d="M48.8497,12.5761c0.9692-0.8502,2.2395-1.3655,3.6301-1.3655c3.0417,0,5.5076,2.4657,5.5076,5.5075 c0,1.1088-0.3277,2.1411-0.8914,3.0052"/>
      <path fill="none" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="2" d="M23.1504,12.5761c-0.9693-0.8502-2.2396-1.3655-3.6302-1.3655c-3.0417,0-5.5075,2.4657-5.5075,5.5075 c0,1.1088,0.3276,2.1411,0.8914,3.0052"/>
      <circle cx="36" cy="36.2941" r="23" fill="none" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="2"/>
      <line x1="36.0257" x2="36.0257" y1="18.9893" y2="35.9893" fill="none" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="2"/>
      <line x1="35.9742" x2="29.9742" y1="35.9349" y2="46.3272" fill="none" stroke="#000000" stroke-linecap="round" stroke-linejoin="round" stroke-miterlimit="10" stroke-width="2.0785"/>
    </g>
    </svg>
    """
